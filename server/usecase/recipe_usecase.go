package usecase

import (
	"context"
	"errors"
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
	if len(ingredients) > 0 {
		var ingredientVecs [][]float32
		for _, name := range ingredients {
			vec, err := u.LLMClient.EmbedText(ctx, name)
			if err != nil {
				return nil, err
			}
			ingredientVecs = append(ingredientVecs, vec)
		}
		return u.Repo.GetRecipesByIngredientVectors(ctx, userId, ingredientVecs)
	}
	if title != "" {
		titleVec, err := u.LLMClient.EmbedText(ctx, title)
		if err != nil {
			return nil, err
		}
		return u.Repo.GetRecipesByTitleVector(ctx, userId, titleVec)
	}
	return nil, errors.New("no search parameter")
}
