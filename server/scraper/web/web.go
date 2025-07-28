package web

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/PuerkitoBio/goquery"
)

func ScrapeWebPage(ctx context.Context, input string) (string, error) {
	client := &http.Client{Timeout: 10 * time.Second}
	req, _ := http.NewRequestWithContext(ctx, "GET", input, nil)
	req.Header.Set("User-Agent", "Mozilla/5.0 ...")
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	doc, err := goquery.NewDocumentFromReader(resp.Body)
	if err != nil {
		return "", err
	}

	var recipeText string
	doc.Find("script[type='application/ld+json']").EachWithBreak(func(i int, s *goquery.Selection) bool {
		jsonText := s.Text()
		var data map[string]interface{}
		if err := json.Unmarshal([]byte(jsonText), &data); err != nil {
			return true
		}
		if data["@type"] == "Recipe" {
			if name, ok := data["name"].(string); ok {
				recipeText += "【タイトル】\n" + name + "\n\n"
			}
			if ingredients, ok := data["recipeIngredient"].([]interface{}); ok {
				recipeText += "【材料】\n"
				for _, ing := range ingredients {
					if ingStr, ok := ing.(string); ok {
						recipeText += ingStr + "\n"
					}
				}
				recipeText += "\n"
			}
			if instructions, ok := data["recipeInstructions"].([]interface{}); ok {
				recipeText += "【手順】\n"
				for _, step := range instructions {
					switch stepVal := step.(type) {
					case map[string]interface{}:
						if text, ok := stepVal["text"].(string); ok {
							recipeText += text + "\n"
						}
					case string:
						recipeText += stepVal + "\n"
					}
				}
				recipeText += "\n"
			}
			if img, ok := data["image"].(string); ok {
				recipeText += "【画像】" + img + "\n"
			}
			return false
		}
		return true
	})

	if recipeText != "" {
		return recipeText, nil
	}

	rawText := doc.Text()
	normalized := strings.Join(strings.Fields(rawText), " ")
	maxLen := 1200
	if len(normalized) > maxLen {
		normalized = normalized[:maxLen]
	}
	return normalized, nil
}
