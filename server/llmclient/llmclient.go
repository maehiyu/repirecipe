package llmclient

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"repirecipe/entity"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	bedrock "github.com/aws/aws-sdk-go-v2/service/bedrockruntime"
)

type LLMClient interface {
	GenerateRecipeDetail(ctx context.Context, text string) (*entity.RecipeDetail, error)
	EmbedText(ctx context.Context, text string) ([]float32, error)
}

type BedrockLLMClient struct {
	client  *bedrock.Client
	modelId string
}

func NewLLMClient() LLMClient {
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion("ap-northeast-1"))
	if err != nil {
		panic(fmt.Sprintf("failed to load AWS config: %v", err))
	}
	client := bedrock.NewFromConfig(cfg)
	return &BedrockLLMClient{client: client, modelId: "anthropic.claude-instant-v1"}
}

func (c *BedrockLLMClient) GenerateRecipeDetail(ctx context.Context, text string) (*entity.RecipeDetail, error) {
	prompt := fmt.Sprintf(`
Human: 以下のテキストからレシピ情報を抽出し、以下のJSON形式で出力してください。

【出力形式】
{
  "title": "レシピ名",
  "ingredientGroups": [
    {
      "title": "グループ名（例: 材料、タレ、衣 など。なければ空文字）",
      "ingredients": [
        {
          "ingredientName": "材料名",
          "amount": "分量（なければ空文字）"
        }
      ]
    }
  ]
}

【抽出ルール】
- 材料がグループ分けされていない場合は、ingredientGroups配列に1つだけtitleを空文字("")で入れてください。
- 材料名や分量が不明な場合は空文字にしてください。
- 出力はJSONのみ、説明文や記号は不要です。

### テキスト：
---
%s
---
Assistant:
`, text)

	payload := map[string]interface{}{
		"prompt":               prompt,
		"max_tokens_to_sample": 4000,
	}
	body, _ := json.Marshal(payload)

	input := &bedrock.InvokeModelInput{
		ModelId:     aws.String(c.modelId),
		ContentType: aws.String("application/json"),
		Body:        body,
	}

	resp, err := c.client.InvokeModel(ctx, input)
	if err != nil {
		return nil, err
	}

	// Claudeのレスポンスは {"completion": "..."} の形式
	var result struct {
		Completion string `json:"completion"`
	}
	if err := json.Unmarshal(resp.Body, &result); err != nil {
		return nil, errors.New("failed to parse LLM response")
	}

	// completion部分をRecipeDetailとしてパース
	var recipe entity.RecipeDetail
	if err := json.Unmarshal([]byte(result.Completion), &recipe); err != nil {
		return nil, errors.New("Claudeの出力がRecipeDetail形式のJSONではありません")
	}

	return &recipe, nil
}

const embeddingModelId = "amazon.titan-embed-text-v2:0" 

func (c *BedrockLLMClient) EmbedText(ctx context.Context, text string) ([]float32, error) {
	payload := map[string]interface{}{
		"inputText": text,
		"dimensions": 1024, 
	}
	body, _ := json.Marshal(payload)

	input := &bedrock.InvokeModelInput{
		ModelId:     aws.String(embeddingModelId),
		ContentType: aws.String("application/json"),
		Body:        body,
	}

	resp, err := c.client.InvokeModel(ctx, input)
	if err != nil {
		return nil, err
	}

	// Titan Embeddingsのレスポンス例: {"embedding":[...]}
	var result struct {
		Embedding []float32 `json:"embedding"`
	}
	if err := json.Unmarshal(resp.Body, &result); err != nil {
		return nil, err
	}

	return result.Embedding, nil
}

// ファイル末尾に追加
func strPtr(s string) *string {
	return &s
}
