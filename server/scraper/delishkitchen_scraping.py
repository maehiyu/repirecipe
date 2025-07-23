import requests
from bs4 import BeautifulSoup
from datetime import datetime
import json

class RecipeDetail:
    def __init__(self, title: str, ingredients: list, thumbnail_url: str = None, video_url: str = None, memo: str = None):
        self.title = title
        self.thumbnail_url = thumbnail_url or "https://example.com/default_thumbnail.jpg"
        self.video_url = video_url
        self.ingredients = ingredients
        self.memo = memo or ""
        self.created_at = datetime.utcnow().isoformat()
        self.last_cooked_at = None

    def to_dict(self):
        return {
            "title": self.title,
            "thumbnailUrl": self.thumbnail_url,
            "videoUrl": self.video_url,
            "ingredients": self.ingredients,
            "memo": self.memo,
            "createdAt": self.created_at,
            "lastCookedAt": self.last_cooked_at,
        }

def get_recipe_from_delishkitchen(url):
    """
    delishkitchenのレシピURLからレシピ情報を取得する関数
    """
    try:
        # ヘッダーを設定してリクエスト
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'ja,en-US;q=0.7,en;q=0.3',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1'
        }
        
        # ページの取得
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        # BeautifulSoupでパース
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # レシピ情報の取得
        recipe = {}
        
        # タイトル
        title_elem = soup.find('h1', attrs={'data-v-ee886a7e': ''})
        if title_elem:
            lead = title_elem.find('span', class_='lead')
            title = title_elem.find('span', class_='title')
            recipe['title'] = f"{lead.text.strip()} {title.text.strip()}" if lead and title else title_elem.text.strip()
        
        # サムネイルURL（動画のプレビュー画像）
        video_elem = soup.find('video', class_='video-js')
        if video_elem:
            # poster属性を確認
            poster_url = video_elem.get('poster', '')
            if not poster_url:
                # data-poster属性を確認
                poster_url = video_elem.get('data-poster', '')
            recipe['thumbnailUrl'] = poster_url
        else:
            recipe['thumbnailUrl'] = ''
        
        # 動画URL（サイトのURLを使用）
        recipe['videoUrl'] = url
        
        # 材料情報
        ingredients = []
        ingredients_elem = soup.find('div', class_='recipe-ingredients')
        if ingredients_elem:
            for item in ingredients_elem.find_all('li', class_='ingredient'):
                name_elem = item.find('span', class_='ingredient-name')
                amount_elem = item.find('span', class_='ingredient-serving')
                if name_elem and amount_elem:
                    ingredients.append({
                        'ingredientName': name_elem.text.strip(),
                        'amount': amount_elem.text.strip()
                    })
        recipe['ingredients'] = ingredients
        
        # メモ（空文字列）
        recipe['memo'] = ''
        
        # 作成日時
        recipe['createdAt'] = datetime.now().isoformat()
        
        return recipe
        
    except Exception as e:
        print(f"delishkitchenからのレシピ取得中にエラーが発生しました: {str(e)}")
        return None

def main():
    # テスト用のURL（実際のレシピURLに置き換えてください）
    test_url = "https://delishkitchen.tv/recipes/167612989870965228"
    
    # レシピ情報の取得
    recipe = get_recipe_from_delishkitchen(test_url)
    
    if recipe:
        # 結果をJSON形式で表示
        print(json.dumps(recipe, ensure_ascii=False, indent=2))
    else:
        print("レシピ情報の取得に失敗しました")

if __name__ == '__main__':
    main() 