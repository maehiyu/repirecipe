package scraper

import (
	"context"

	"repirecipe/scraper/instagram"
	"repirecipe/scraper/web"
	"repirecipe/scraper/youtube"
)

type RecipeScraper struct{}

func (r *RecipeScraper) ScrapeText(ctx context.Context, input string) (string, error) {
	switch {
	case youtube.IsYouTubeURL(input):
		return youtube.FetchFromYouTubeAPI(input)
	case instagram.IsInstagramURL(input):
		return instagram.FetchFromInstagramAPI(input)
	default:
		return web.ScrapeWebPage(ctx, input)
	}
}
