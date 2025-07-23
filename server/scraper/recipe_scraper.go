package scraper

import (
	"context"
	"net/http"
	"repirecipe/entity"
	"repirecipe/usecase"
	"strings"
	"time"

	"github.com/PuerkitoBio/goquery"
)

type CookpadScraper struct{}

func (c *CookpadScraper) Scrape(ctx context.Context, input string) (*entity.RecipeDetail, error) {
	client := &http.Client{Timeout: 10 * time.Second}
	req, _ := http.NewRequestWithContext(ctx, "GET", input, nil)
	req.Header.Set("User-Agent", "Mozilla/5.0 ...") // 必要に応じてヘッダー追加

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	doc, err := goquery.NewDocumentFromReader(resp.Body)
	if err != nil {
		return nil, err
	}

	// タイトル
	title := doc.Find("h1.text-cookpad").Text()

	// サムネイル
	thumbnail, _ := doc.Find("img[alt*='レシピのメイン写真']").Attr("src")

	// 材料
	var ingredients []entity.Ingredient
	doc.Find("div.ingredients-list li.justified-quantity-and-name").Each(func(i int, s *goquery.Selection) {
		name := s.Find("span").Text()
		amount := s.Find("bdi").Text()
		var amountPtr *string
		if amount != "" {
			amountPtr = &amount
		}
		if name != "" {
			ingredients = append(ingredients, entity.Ingredient{
				IngredientName: name,
				Amount:         amountPtr,
			})
		}
	})

	return &entity.RecipeDetail{
		Title:        title,
		ThumbnailURL: strPtr(thumbnail),
		VideoURL:     strPtr(input),
		IngredientGroups: []entity.IngredientGroup{
			{
				GroupID:     "group-1",
				Title:       nil,
				OrderNum:    1,
				Ingredients: ingredients,
			},
		},
		Memo:         strPtr(""),
		CreatedAt:    time.Now().Format(time.RFC3339),
		LastCookedAt: nil,
	}, nil
}

type DelishKitchenScraper struct{}

func (d *DelishKitchenScraper) Scrape(ctx context.Context, input string) (*entity.RecipeDetail, error) {
	client := &http.Client{Timeout: 10 * time.Second}
	req, _ := http.NewRequestWithContext(ctx, "GET", input, nil)
	req.Header.Set("User-Agent", "Mozilla/5.0 ...") // 必要に応じてヘッダー追加

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	doc, err := goquery.NewDocumentFromReader(resp.Body)
	if err != nil {
		return nil, err
	}

	// タイトル
	titleElem := doc.Find("h1[data-v-ee886a7e]")
	lead := titleElem.Find("span.lead").Text()
	title := titleElem.Find("span.title").Text()
	fullTitle := strings.TrimSpace(lead + " " + title)
	if fullTitle == "" {
		fullTitle = titleElem.Text()
	}

	// サムネイル
	thumbnail := ""
	videoElem := doc.Find("video.video-js")
	if videoElem.Length() > 0 {
		thumbnail, _ = videoElem.Attr("poster")
		if thumbnail == "" {
			thumbnail, _ = videoElem.Attr("data-poster")
		}
	}

	// 材料
	var ingredients []entity.Ingredient
	doc.Find("div.recipe-ingredients li.ingredient").Each(func(i int, s *goquery.Selection) {
		name := s.Find("span.ingredient-name").Text()
		amount := s.Find("span.ingredient-serving").Text()
		var amountPtr *string
		if amount != "" {
			amountPtr = &amount
		}
		if name != "" {
			ingredients = append(ingredients, entity.Ingredient{
				IngredientName: name,
				Amount:         amountPtr,
			})
		}
	})

	return &entity.RecipeDetail{
		Title:        fullTitle,
		ThumbnailURL: strPtr(thumbnail),
		VideoURL:     strPtr(input),
		IngredientGroups: []entity.IngredientGroup{
			{
				GroupID:     "group-1",
				Title:       nil,
				OrderNum:    1,
				Ingredients: ingredients,
			},
		},
		Memo:         strPtr(""),
		CreatedAt:    time.Now().Format(time.RFC3339),
		LastCookedAt: nil,
	}, nil
}

func strPtr(s string) *string {
	return &s
}

// ScraperFactory returns the appropriate Scraper implementation based on the input (e.g., URL)
func ScraperFactory(input string) usecase.Scraper {
	if strings.Contains(input, "cookpad.com") {
		return &CookpadScraper{}
	}
	if strings.Contains(input, "delishkitchen.tv") {
		return &DelishKitchenScraper{}
	}
	// 他サービス用のScraperもここで分岐可能
	return nil // サポート外の場合はnilやエラーを返す
}
