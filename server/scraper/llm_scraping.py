import os
import re
import json
import boto3
from apiclient.discovery import build
from datetime import datetime
from uuid import uuid4

# YouTube API キーを環境変数から取得
# youtube_api_key = os.environ.get("YOUTUBE_API_KEY")
youtube_api_key = "AIzaSyAxUiLBqQrQ36eXPUPMVnYPsafnZfp4VqU"
youtube_client = build("youtube", "v3", developerKey=youtube_api_key)

# Bedrock Runtime クライアントを作成
bedrock_runtime = boto3.client(service_name='bedrock-runtime', region_name="ap-northeast-1")

class Ingredient:
    def __init__(self, ingredientName: str, amount: str = None):
        self.ingredientName = ingredientName
        self.amount = amount
    
    def to_dict(self):
        return {"ingredientName": self.ingredientName, "amount": self.amount}

class RecipeDetail:
    def __init__(self, title: str, ingredients: list, thumbnail_url: str = None, video_url: str = None, memo: str = None):
        self.title = title
        self.thumbnail_url = thumbnail_url or "https://example.com/default_thumbnail.jpg"
        self.video_url = video_url
        self.ingredients = [Ingredient(**ing) for ing in ingredients]
        self.memo = memo or ""
        self.created_at = datetime.utcnow().isoformat()
        self.last_cooked_at = None

    def to_dict(self):
        return {
            "title": self.title,
            "thumbnailUrl": self.thumbnail_url,
            "videoUrl": self.video_url,
            "ingredients": [ing.to_dict() for ing in self.ingredients],
            "memo": self.memo,
            "createdAt": self.created_at,
            "lastCookedAt": self.last_cooked_at,
        }

def extract_ingredients(text):
    prompt = f"""
\n\nHuman:以下の概要欄テキストから、料理ごとに材料と分量を抽出し、JSON形式で出力してください。

【抽出ルール】
- 各レシピの開始には、料理名のみを含むオブジェクトを1つ追加してください。
  - このとき、キー `ingredientName` に料理名、`amount` に空文字 `""` を設定してください。
  - 料理名の先頭には必ず `・`（中点）を付けてください。
- レシピ名が記載されていない場合は、レシピ名の挿入は省略してください。
- 材料が「衣」「タレ」などに分類されている場合は、それらのセクション名も `ingredientName` に設定し、`amount` は空文字にしてください。
- 材料には `ingredientName` に材料名、`amount` に分量を記録してください。
  - 分量が書かれていない場合は `amount` を空文字 `""` にしてください。
- URLやSNSリンク、コメントなどのノイズ情報はすべて無視してください。
- 出力は JSON 配列形式とし、前後に説明文や記号をつけず、**厳密にJSONのみ**を返してください。

### 概要欄テキスト：
---
{text}
---
\n\nAssistant:
"""
    response = bedrock_runtime.invoke_model(
        modelId="anthropic.claude-instant-v1",
        contentType="application/json",
        accept="application/json",
        body=json.dumps({"prompt": prompt, "max_tokens_to_sample": 4000})
    )
    
    response_body = json.loads(response["body"].read().decode("utf-8"))
    completion_text = response_body["completion"].strip()
    try:
        ingredients_list = json.loads(completion_text)
        # リストを辞書形式に変換
        return {
            "ingredients": ingredients_list,
            "memo": ""
        }
    except json.JSONDecodeError:
        print("Claude Instant の出力がJSON形式ではありません:", completion_text)
        # JSONデコードエラーが発生した場合、エラーメッセージと元のテキストをmemoとして返す
        error_message = "材料の取得に失敗しました。\n\n"
        return {
            "ingredients": [],
            "memo": error_message + text
        }

def web_scraping(youtube, url):
    """
    YouTube の説明文を取得する関数
    """

    UrlPatterns = [
        r"https?://(?:www\.|m\.)?youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})",
        r"https?://(?:www\.|m\.)?youtube\.com/shorts/([a-zA-Z0-9_-]{11})",
        r"https?://youtu\.be/([a-zA-Z0-9_-]{11})"
    ]

    for pattern in UrlPatterns:
        match = re.search(pattern, url)
        if match:
            break
    if match:
        video_id = match.group(1)
    else:
        print("Error : This URL is invalid. Please register correct YouTube URL.")
        return None

    # Send API request
    request = youtube.videos().list(
        part="snippet",
        id = video_id
    )
    response = request.execute()

    # Get results
    if "items" not in response or len(response["items"]) == 0:
        print("Error : Can't finding the YouTube")
        return None
    
    video_info = response["items"][0]
    snippet = video_info["snippet"]

    video_data = {
        "title": snippet["title"],
        "description":  snippet["description"],
        "channelTitle": snippet["channelTitle"],
        "thumbnails": snippet["thumbnails"]["medium"]["url"], # default, medium, high, standard, maxres
        "URL": url
    }

    return video_data

def get_recipe_from_youtube(youtubeUrl):
    """
    YouTube の動画からレシピ情報を抽出する関数
    """
    video_data = web_scraping(youtube_client, youtubeUrl)
    description = video_data["description"]
    result = extract_ingredients(description)
    
    # 材料リストとメモを取得
    ingredients = result.get("ingredients", [])
    memo = result.get("memo", "")
    
    # RecipeDetail オブジェクトを作成して返す
    recipe = RecipeDetail(
        title=video_data["title"],
        ingredients=ingredients,
        thumbnail_url=video_data["thumbnails"],
        video_url=video_data["URL"],
        memo=memo
    )

    # RecipeDetail を JSON 形式で出力
    return recipe.to_dict()
