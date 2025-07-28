package scraper

import (
	"context"
	"testing"
)

func TestRecipeScraper_ScrapeText(t *testing.T) {
	scraper := &RecipeScraper{}
	url := "https://cookpad.com/jp/recipes/22640981"

	result, err := scraper.ScrapeText(context.Background(), url)
	if err != nil {
		t.Fatalf("ScrapeText failed: %v", err)
	}
	t.Logf("Scraped Text:\n%s", result)
	if result == "" {
		t.Errorf("Failed to get any text from the page")
	}
}

func TestRecipeScraper_ScrapeText_YouTube(t *testing.T) {
	scraper := &RecipeScraper{}
	// 通常のYouTube動画
	url := "https://www.youtube.com/watch?v=xGKn7TD9jaM"
	// Shortsの場合はこちら
	// url := "https://www.youtube.com/shorts/abcdefghijk"

	result, err := scraper.ScrapeText(context.Background(), url)
	if err != nil {
		t.Fatalf("ScrapeText failed: %v", err)
	}
	t.Logf("Scraped Text:\n%s", result)
	if result == "" {
		t.Errorf("Failed to get any text from the YouTube page")
	}
}
