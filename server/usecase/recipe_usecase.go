package usecase

import (
	"context"
	"fmt"
	"log"
	"repirecipe/entity"

	"github.com/google/uuid"
)

// ユースケース層でRepositoryインターフェースを定義
type Repository interface {
	FindByID(ctx context.Context, id string) (*entity.RecipeDetail, error)
	FindAllByUserID(ctx context.Context, userId string) ([]*entity.RecipeSummary, error)
	Create(ctx context.Context, userId string, recipe *entity.RecipeDetail) error
	Update(ctx context.Context, recipe *entity.RecipeDetail) error
	Delete(ctx context.Context, userId string, recipeId string) error
	DeleteAllByUserID(ctx context.Context, userId string) error
	GetRecipesByIngredientVectors(ctx context.Context, userId string, ingredientVecs [][]float32) ([]*entity.RecipeSummary, error)
	GetRecipesByTitleVector(ctx context.Context, userId string, titleVec []float32) ([]*entity.RecipeSummary, error)
}

type Scraper interface {
	ScrapeText(ctx context.Context, input string) (string, error)
}

type LLMClient interface {
	GenerateRecipeDetail(ctx context.Context, text string) (*entity.RecipeDetail, error)
	EmbedText(ctx context.Context, text string) ([]float32, error) // 追加
}

type RecipeUsecase struct {
	Repo      Repository
	Scraper   Scraper
	LLMClient LLMClient
}

func NewRecipeUsecase(repo Repository, scraper Scraper, llmClient LLMClient) *RecipeUsecase {
	return &RecipeUsecase{Repo: repo, Scraper: scraper, LLMClient: llmClient}
}

func (u *RecipeUsecase) GetRecipeByID(ctx context.Context, id string) (*entity.RecipeDetail, error) {
	return u.Repo.FindByID(ctx, id)
}

func (u *RecipeUsecase) GetRecipes(ctx context.Context, userId string) ([]*entity.RecipeSummary, error) {
	return u.Repo.FindAllByUserID(ctx, userId)
}

func (u *RecipeUsecase) CreateRecipe(ctx context.Context, userId string, recipe *entity.RecipeDetail) error {
	// Usecase層でIDとOrderNumを付与
	if recipe.RecipeID == "" {
		recipe.RecipeID = uuid.New().String()
	}
	for gi := range recipe.IngredientGroups {
		if recipe.IngredientGroups[gi].GroupID == "" {
			recipe.IngredientGroups[gi].GroupID = uuid.New().String()
		}
		recipe.IngredientGroups[gi].OrderNum = gi + 1
		for ii := range recipe.IngredientGroups[gi].Ingredients {
			if recipe.IngredientGroups[gi].Ingredients[ii].ID == "" {
				recipe.IngredientGroups[gi].Ingredients[ii].ID = uuid.New().String()
			}
			recipe.IngredientGroups[gi].Ingredients[ii].OrderNum = ii + 1
		}
	}

	// --- ベクトル化を追加 ---
	// タイトル
	titleVec, err := u.LLMClient.EmbedText(ctx, recipe.Title)
	if err != nil {
		return err
	}
	recipe.TitleVector = titleVec

	// 材料ごと
	for gi := range recipe.IngredientGroups {
		for ii := range recipe.IngredientGroups[gi].Ingredients {
			ing := &recipe.IngredientGroups[gi].Ingredients[ii]
			vec, err := u.LLMClient.EmbedText(ctx, ing.IngredientName)
			if err != nil {
				return err
			}
			ing.IngredientVector = vec
		}
	}

	if err := recipe.Validate(); err != nil {
		return err
	}
	return u.Repo.Create(ctx, userId, recipe)
}

func (u *RecipeUsecase) UpdateRecipe(ctx context.Context, recipe *entity.RecipeDetail) error {
	// IDとOrderNumの再割り当て
	if recipe.RecipeID == "" {
		recipe.RecipeID = uuid.New().String()
	}
	for gi := range recipe.IngredientGroups {
		if recipe.IngredientGroups[gi].GroupID == "" {
			recipe.IngredientGroups[gi].GroupID = uuid.New().String()
		}
		recipe.IngredientGroups[gi].OrderNum = gi + 1
		for ii := range recipe.IngredientGroups[gi].Ingredients {
			if recipe.IngredientGroups[gi].Ingredients[ii].ID == "" {
				recipe.IngredientGroups[gi].Ingredients[ii].ID = uuid.New().String()
			}
			recipe.IngredientGroups[gi].Ingredients[ii].OrderNum = ii + 1
		}
	}

	// --- ベクトル化を追加 ---
	titleVec, err := u.LLMClient.EmbedText(ctx, recipe.Title)
	if err != nil {
		return err
	}
	recipe.TitleVector = titleVec

	for gi := range recipe.IngredientGroups {
		for ii := range recipe.IngredientGroups[gi].Ingredients {
			ing := &recipe.IngredientGroups[gi].Ingredients[ii]
			vec, err := u.LLMClient.EmbedText(ctx, ing.IngredientName)
			if err != nil {
				return err
			}
			ing.IngredientVector = vec
		}
	}

	if err := recipe.Validate(); err != nil {
		return err
	}
	return u.Repo.Update(ctx, recipe)
}

func (u *RecipeUsecase) DeleteRecipe(ctx context.Context, userId string, recipeId string) error {
	return u.Repo.Delete(ctx, userId, recipeId)
}

func (u *RecipeUsecase) ScrapeRecipe(ctx context.Context, input string) (*entity.RecipeDetail, error) {
	text, err := u.Scraper.ScrapeText(ctx, input)
	if err != nil {
		return nil, err
	}

	return u.LLMClient.GenerateRecipeDetail(ctx, text)
}

func (u *RecipeUsecase) DeleteRecipesByUserID(ctx context.Context, userId string) error {
	return u.Repo.DeleteAllByUserID(ctx, userId)
}

func (u *RecipeUsecase) SearchRecipes(ctx context.Context, userId string, ingredients []string, title string) ([]*entity.RecipeSummary, error) {
	log.Printf("SearchRecipes called - userId: %s, ingredients: %v, title: %s", userId, ingredients, title)

	// 材料検索とタイトル検索の両方が空の場合
	if len(ingredients) == 0 && title == "" {
		return []*entity.RecipeSummary{}, nil
	}

	var results []*entity.RecipeSummary
	var err error

	// 材料検索
	if len(ingredients) > 0 {
		log.Printf("Searching by ingredients: %v", ingredients)
		// EmbedTextの呼び出しでエラーが起きている可能性
		ingredientVecs := make([][]float32, len(ingredients))
		for i, ingredient := range ingredients {
			vec, embedErr := u.LLMClient.EmbedText(ctx, ingredient)
			if embedErr != nil {
				log.Printf("Error embedding ingredient '%s': %v", ingredient, embedErr)
				return nil, fmt.Errorf("failed to embed ingredient '%s': %w", ingredient, embedErr)
			}
			ingredientVecs[i] = vec
		}

		results, err = u.Repo.GetRecipesByIngredientVectors(ctx, userId, ingredientVecs)
		if err != nil {
			log.Printf("Error getting recipes by ingredient vectors: %v", err)
			return nil, fmt.Errorf("failed to search by ingredients: %w", err)
		}
	}

	// タイトル検索
	if title != "" {
		log.Printf("Searching by title: %s", title)
		titleVec, embedErr := u.LLMClient.EmbedText(ctx, title)
		if embedErr != nil {
			log.Printf("Error embedding title '%s': %v", title, embedErr)
			return nil, fmt.Errorf("failed to embed title: %w", embedErr)
		}

		titleResults, err := u.Repo.GetRecipesByTitleVector(ctx, userId, titleVec)
		if err != nil {
			log.Printf("Error getting recipes by title vector: %v", err)
			return nil, fmt.Errorf("failed to search by title: %w", err)
		}

		if len(ingredients) == 0 {
			results = titleResults
		} else {
			// 材料検索とタイトル検索の結果をマージ
			results = mergeResults(results, titleResults)
		}
	}

	log.Printf("Search completed, found %d results", len(results))
	return results, nil
}

func mergeResults(ingredientResults, titleResults []*entity.RecipeSummary) []*entity.RecipeSummary {
	// 簡単な実装：IDでユニークにする
	seen := make(map[string]bool)
	var merged []*entity.RecipeSummary

	for _, r := range ingredientResults {
		if !seen[r.RecipeID] {
			merged = append(merged, r)
			seen[r.RecipeID] = true
		}
	}

	for _, r := range titleResults {
		if !seen[r.RecipeID] {
			merged = append(merged, r)
			seen[r.RecipeID] = true
		}
	}

	return merged
}
