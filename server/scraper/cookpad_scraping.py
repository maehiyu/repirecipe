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

def get_recipe_from_cookpad(url):
    """
    クックパッドのレシピURLからレシピ情報を取得する関数
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
        title_elem = soup.find('h1', class_=lambda x: x and 'text-cookpad' in x)
        recipe['title'] = title_elem.text.strip() if title_elem else ''
        
        # サムネイルURL
        thumbnail_elem = soup.find('img', alt=lambda x: x and 'レシピのメイン写真' in x)
        recipe['thumbnailUrl'] = thumbnail_elem['src'] if thumbnail_elem and 'src' in thumbnail_elem.attrs else ''
        
        # 動画URL（サイトのURLを使用）
        recipe['videoUrl'] = url
        
        # 材料情報
        ingredients = []
        ingredients_elem = soup.find('div', class_='ingredients-list')
        if ingredients_elem:
            for item in ingredients_elem.find_all('li', class_='justified-quantity-and-name'):
                name_elem = item.find('span')
                amount_elem = item.find('bdi')
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
        print(f"クックパッドからのレシピ取得中にエラーが発生しました: {str(e)}")
        return None

def main():
    # テスト用のURL（実際のレシピURLに置き換えてください）
    test_url = "https://cookpad.com/jp/recipes/22640981-%E3%82%81%E3%81%A3%E3%81%A1%E3%82%83%E3%82%B8%E3%83%A5%E3%83%BC%E3%82%B7%E3%83%BC%E9%B6%8F%E3%81%AE%E5%94%90%E6%8F%9A%E3%81%92"
    
    # レシピ情報の取得
    recipe = get_recipe_from_cookpad(test_url)
    
    if recipe:
        # 結果をJSON形式で表示
        print(json.dumps(recipe, ensure_ascii=False, indent=2))
    else:
        print("レシピ情報の取得に失敗しました")

if __name__ == '__main__':
    main() 