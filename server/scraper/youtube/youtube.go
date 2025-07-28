package youtube

import (
	"context"
	"errors"
	"os"
	"regexp"
	"strings"

	"google.golang.org/api/option"
	"google.golang.org/api/youtube/v3"
)

var youtubeService *youtube.Service

func init() {
	apiKey := os.Getenv("YOUTUBE_API_KEY")
	if apiKey != "" {
		service, err := youtube.NewService(
			context.Background(),
			option.WithAPIKey(apiKey),
		)
		if err == nil {
			youtubeService = service
		}
	}
}

func IsYouTubeURL(url string) bool {
	return strings.Contains(url, "youtube.com") || strings.Contains(url, "youtu.be")
}

func FetchFromYouTubeAPI(url string) (string, error) {
	if youtubeService == nil {
		return "", errors.New("YouTube APIクライアントが初期化されていません")
	}
	videoID := extractYouTubeVideoID(url)
	if videoID == "" {
		return "", errors.New("YouTube動画IDが取得できませんでした")
	}
	call := youtubeService.Videos.List([]string{"snippet"}).Id(videoID)
	resp, err := call.Do()
	if err != nil || len(resp.Items) == 0 {
		return "", errors.New("YouTube APIから動画情報を取得できませんでした")
	}
	desc := resp.Items[0].Snippet.Description
	title := resp.Items[0].Snippet.Title
	return "【タイトル】\n" + title + "\n\n【説明】\n" + desc, nil
}

func extractYouTubeVideoID(u string) string {
	patterns := []string{
		`https?://(?:www\.|m\.)?youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})`,
		`https?://(?:www\.|m\.)?youtube\.com/shorts/([a-zA-Z0-9_-]{11})`,
		`https?://youtu\.be/([a-zA-Z0-9_-]{11})`,
	}
	for _, pat := range patterns {
		re := regexp.MustCompile(pat)
		m := re.FindStringSubmatch(u)
		if len(m) == 2 {
			return m[1]
		}
	}
	return ""
}
