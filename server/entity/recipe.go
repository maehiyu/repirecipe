package entity

import (
	"errors"
)

type RecipeSummary struct {
	RecipeID        string   `json:"recipeId"`
	Title           string   `json:"title"`
	ThumbnailURL    *string   `json:"thumbnailUrl"`
	IngredientsName []string `json:"ingredientsName"`
	CreatedAt       string   `json:"createdAt"`
}

type Ingredient struct {
	ID             string `json:"id"`
	IngredientName string `json:"ingredientName"`
	Amount         *string `json:"amount"`
	OrderNum       int    `json:"orderNum"`
}

func (i *Ingredient) Validate() error {
	if i.IngredientName == "" {
		return errors.New("ingredient name is required")
	}
	return nil
}

type IngredientGroup struct {
	GroupID     string       `json:"groupId"`
	Title       *string       `json:"title"`
	OrderNum    int          `json:"orderNum"`
	Ingredients []Ingredient `json:"ingredients"`
}

type RecipeDetail struct {
	ID               string            `json:"id"`
	RecipeID         string            `json:"recipeId"`
	Title            string            `json:"title"`
	ThumbnailURL     *string            `json:"thumbnailUrl,omitempty"`
	VideoURL         *string            `json:"videoUrl,omitempty"`
	IngredientGroups []IngredientGroup `json:"ingredientGroups,omitempty"`
	Memo             *string            `json:"memo"`
	CreatedAt        string            `json:"createdAt,omitempty"`
	LastCookedAt     *string            `json:"lastCookedAt,omitempty"`
}

func (r *RecipeDetail) Validate() error {
	if r.Title == "" {
		return errors.New("title is required")
	}
	if len(r.IngredientGroups) == 0 {
		return errors.New("at least one ingredient group is required (if you do not use groups, create one group with an empty title)")
	}
	for _, group := range r.IngredientGroups {
		// グループ名が空でもOK（単一グループ用途）
		if len(group.Ingredients) == 0 {
			return errors.New("each group must have at least one ingredient")
		}
		for _, ing := range group.Ingredients {
			if err := ing.Validate(); err != nil {
				return err
			}
		}
	}
	return nil
}
