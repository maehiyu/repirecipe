package usecase

import (
	"context"
	"repirecipe/entity"
)

// ユースケース層でRepositoryインターフェースを定義
type RecipeRepository interface {
	FindByID(ctx context.Context, id string) (*entity.RecipeDetail, error)
	FindAllByUserID(ctx context.Context, userId string) ([]*entity.RecipeSummary, error)
	Create(ctx context.Context, userId string, recipe *entity.RecipeDetail) error
	// Update(ctx context.Context, userId string, recipe *entity.RecipeDetail) error
	// Search(ctx context.Context, userId string, query string) ([]*entity.RecipeSummary, error)
}

type RecipeUsecase struct {
	RecipeRepo RecipeRepository
}

func NewRecipeUsecase(repo RecipeRepository) *RecipeUsecase {
	return &RecipeUsecase{RecipeRepo: repo}
}

func (u *RecipeUsecase) GetRecipeByID(ctx context.Context, id string) (*entity.RecipeDetail, error) {
	return u.RecipeRepo.FindByID(ctx, id)
}

func (u *RecipeUsecase) GetRecipes(ctx context.Context, userId string) ([]*entity.RecipeSummary, error) {
	return u.RecipeRepo.FindAllByUserID(ctx, userId)
}

func (u *RecipeUsecase) CreateRecipe(ctx context.Context, userId string,recipe *entity.RecipeDetail) error {
	if err := recipe.Validate(); err != nil {
		return err
	}

	return u.RecipeRepo.Create(ctx, userId,recipe)
}
