package usecase

import (
	"context"
	"repirecipe/entity"
)

// ユースケース層でRepositoryインターフェースを定義
type Repository interface {
	FindByID(ctx context.Context, id string) (*entity.RecipeDetail, error)
	FindAllByUserID(ctx context.Context, userId string) ([]*entity.RecipeSummary, error)
	Create(ctx context.Context, userId string, recipe *entity.RecipeDetail) error
	Update(ctx context.Context, recipe *entity.RecipeDetail) error
	Delete(ctx context.Context, recipeId string) error
	// Search(ctx context.Context, userId string, query string) ([]*entity.RecipeSummary, error)
}

type Scraper interface {
	Scrape(ctx context.Context, input string) (*entity.RecipeDetail, error)
}

type RecipeUsecase struct {
	Repo Repository
}

func NewRecipeUsecase(repo Repository) *RecipeUsecase {
	return &RecipeUsecase{Repo: repo}
}

func (u *RecipeUsecase) GetRecipeByID(ctx context.Context, id string) (*entity.RecipeDetail, error) {
	return u.Repo.FindByID(ctx, id)
}

func (u *RecipeUsecase) GetRecipes(ctx context.Context, userId string) ([]*entity.RecipeSummary, error) {
	return u.Repo.FindAllByUserID(ctx, userId)
}

func (u *RecipeUsecase) CreateRecipe(ctx context.Context, userId string, recipe *entity.RecipeDetail) error {
	if err := recipe.Validate(); err != nil {
		return err
	}

	return u.Repo.Create(ctx, userId, recipe)
}

func (u *RecipeUsecase) UpdateRecipe(ctx context.Context, recipe *entity.RecipeDetail) error {
	if err := recipe.Validate(); err != nil {
		return err
	}
	return u.Repo.Update(ctx, recipe)
}

func (u *RecipeUsecase) DeleteRecipe(ctx context.Context, recipeId string) error {
	return u.Repo.Delete(ctx, recipeId)
}
