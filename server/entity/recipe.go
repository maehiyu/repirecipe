package entity

import (
	"errors"
)

type RecipeSummary struct {
	RecipeID        string   `json:"recipeId"`
	Title           string   `json:"title"`
	ThumbnailURL    *string  `json:"thumbnailUrl"`
	IngredientsName []string `json:"ingredientsName"`
	CreatedAt       string   `json:"createdAt"`
}

type Ingredient struct {
	ID               string    `json:"id"`
	IngredientName   string    `json:"ingredientName"`
	Amount           *string   `json:"amount"`
	OrderNum         int       `json:"orderNum"`
	IngredientVector []float32 `json:"-"` // ベクトルはAPIレスポンスに含めない
}

func (i *Ingredient) Validate() error {
	if i.IngredientName == "" {
		return errors.New("ingredient name is required")
	}
	return nil
}

type IngredientGroup struct {
	GroupID     string       `json:"groupId"`
	Title       *string      `json:"title"`
	OrderNum    int          `json:"orderNum"`
	Ingredients []Ingredient `json:"ingredients"`
}

type RecipeDetail struct {
	RecipeID         string            `json:"recipeId"`
	Title            string            `json:"title"`
	ThumbnailURL     *string           `json:"thumbnailUrl,omitempty"`
	VideoURL         *string           `json:"videoUrl,omitempty"`
	IngredientGroups []IngredientGroup `json:"ingredientGroups,omitempty"`
	Memo             *string           `json:"memo"`
	CreatedAt        string            `json:"createdAt,omitempty"`
	LastCookedAt     *string           `json:"lastCookedAt,omitempty"`
	TitleVector      []float32         `json:"-"`
}

func (r *RecipeDetail) Validate() error {
	if r.Title == "" {
		return errors.New("title is required")
	}
	// IngredientGroupsがnilや空でもOK
	if r.IngredientGroups == nil || len(r.IngredientGroups) == 0 {
		return nil
	}
	for _, group := range r.IngredientGroups {
		if len(group.Ingredients) == 0 {
			continue // 空グループは許容
		}
		for _, ing := range group.Ingredients {
			if err := ing.Validate(); err != nil {
				return err
			}
		}
	}
	return nil
}
