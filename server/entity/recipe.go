package entity

import (
	"errors"
	"time"
)

type RecipeSummary struct {
	RecipeID        string     `json:"recipeId"`
	Title           string     `json:"title"`
	ThumbnailURL    *string     `json:"thumbnailUrl"`
	CreatedAt       time.Time  `json:"createdAt"`
	IngredientsName []string   `json:"ingredientsName"`
}

type Ingredient struct {
	ID               string    `json:"id"`
	IngredientName   string    `json:"ingredientName"`
	Amount           *string   `json:"amount"`
	OrderNum         int       `json:"orderNum"`
	IngredientVector []float32 `json:"-"` 
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
	ThumbnailURL     *string            `json:"thumbnailUrl"`
	MediaURL         *string            `json:"mediaUrl"`
	Memo             *string            `json:"memo"`
	CreatedAt        time.Time         `json:"createdAt"`
	LastCookedAt     *time.Time        `json:"lastCookedAt"`
	IngredientGroups []IngredientGroup `json:"ingredientGroups"`
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
