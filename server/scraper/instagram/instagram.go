package instagram

import "strings"

func IsInstagramURL(url string) bool {
	return strings.Contains(url, "instagram.com")
}

func FetchFromInstagramAPI(url string) (string, error) {
	return "Instagram APIから取得したレシピテキスト（ダミー）", nil
}
