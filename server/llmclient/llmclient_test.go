package llmclient

import (
	"context"
	"testing"
)

func TestGenerateRecipeDetail(t *testing.T) {
	client := NewLLMClient()

	// テスト用のYouTube概要欄風テキスト
	testText := `
【材料】（2人分）
・鶏もも肉 300g
・醤油 大さじ2
・酒 大さじ1
・おろし生姜 1片分
・おろしにんにく 1片分
・片栗粉 大さじ3
・サラダ油 適量

【作り方】
1. 鶏もも肉は一口大に切る。
2. ボウルに鶏肉、醤油、酒、生姜、にんにくを入れてよく揉み込み、10分ほど置く。
3. 片栗粉をまぶし、180℃の油でカラッと揚げる。
4. お皿に盛り付けて完成！

#簡単レシピ #唐揚げ #おうちごはん
`

	ctx := context.Background()
	recipe, err := client.GenerateRecipeDetail(ctx, testText)
	if err != nil {
		t.Fatalf("failed to generate recipe detail: %v", err)
	}

	if recipe.Title == "" {
		t.Error("recipe title is empty")
	}
	if len(recipe.IngredientGroups) == 0 {
		t.Error("ingredient groups is empty")
	}
	if len(recipe.IngredientGroups[0].Ingredients) == 0 {
		t.Error("ingredients is empty")
	}

	t.Logf("LLM生成結果: %+v", recipe)
}
