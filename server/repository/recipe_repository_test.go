package repository

import (
	"context"
	"os"
	"repirecipe/entity"
	"testing"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

func init() {
	godotenv.Load(".env.test")
}

func setupTestDB() *recipeRepository {
	repo, err := NewPostgresRepository(
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
	)
	if err != nil {
		panic(err)
	}
	return repo.(*recipeRepository)
}

func cleanupTestDB(repo *recipeRepository) {
	repo.db.Exec(`TRUNCATE ingredients RESTART IDENTITY CASCADE;`)
	repo.db.Exec(`TRUNCATE ingredient_groups RESTART IDENTITY CASCADE;`)
	repo.db.Exec(`TRUNCATE recipes RESTART IDENTITY CASCADE;`)
}

func insertTestRecipe(repo *recipeRepository) {
	repo.db.Exec(`INSERT INTO recipes (recipe_id, user_id, title, thumbnail_url, video_url, memo, created_at, last_cooked_at) VALUES ('recipe-1', 'user-1', 'テストレシピ1', NULL, NULL, NULL, NOW(), NULL);`)
	repo.db.Exec(`INSERT INTO ingredient_groups (group_id, recipe_id, title, order_num) VALUES ('group-1', 'recipe-1', 'title', 1);`)
	repo.db.Exec(`INSERT INTO ingredients (id, group_id, ingredient_name, ingredient_amount, order_num) VALUES ('ing-1', 'group-1', '卵', '1個', 1);`)
	repo.db.Exec(`INSERT INTO ingredients (id, group_id, ingredient_name, ingredient_amount, order_num) VALUES ('ing-2', 'group-1', '牛乳', '100ml', 2);`)
}

func TestFindByID(t *testing.T) {
	repo := setupTestDB()
	cleanupTestDB(repo)
	t.Cleanup(func() { cleanupTestDB(repo) })
	insertTestRecipe(repo)
	ctx := context.Background()

	recipe, err := repo.FindByID(ctx, "recipe-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if recipe.RecipeID != "recipe-1" {
		t.Errorf("unexpected recipe id: %v", recipe.RecipeID)
	}
	// 他のフィールドも検証
}

func TestFindAllByUserID(t *testing.T) {
	repo := setupTestDB()
	cleanupTestDB(repo)
	t.Cleanup(func() { cleanupTestDB(repo) })
	insertTestRecipe(repo)
	ctx := context.Background()

	recipes, err := repo.FindAllByUserID(ctx, "user-1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(recipes) == 0 {
		t.Error("expected at least one recipe")
	}
	if recipes[0].RecipeID != "recipe-1" {
		t.Errorf("unexpected recipe id: %v", recipes[0].RecipeID)
	}
	if recipes[0].Title != "テストレシピ1" {
		t.Errorf("unexpected title: %v", recipes[0].Title)
	}
	if len(recipes[0].IngredientsName) != 2 {
		t.Errorf("unexpected ingredients count: %v", len(recipes[0].IngredientsName))
	}
	if recipes[0].IngredientsName[0] != "卵" {
		t.Errorf("unexpected ingredient: %v", recipes[0].IngredientsName[0])
	}
}

func TestCreateAndFindByID(t *testing.T) {
	repo := setupTestDB()
	cleanupTestDB(repo)
	t.Cleanup(func() { cleanupTestDB(repo) })
	ctx := context.Background()

	// 新規レシピデータ
	recipeId := "recipe-test"
	groupId := "group-test"
	newRecipe := &entity.RecipeDetail{
		RecipeID: recipeId,
		Title:    "新規レシピ",
		IngredientGroups: []entity.IngredientGroup{{
			GroupID:  groupId,
			Title:    nil,
			OrderNum: 1,
			Ingredients: []entity.Ingredient{{
				ID:             "ing-test",
				IngredientName: "小麦粉",
				Amount:         strPtr("100g"),
				OrderNum:       1,
			}},
		}},
	}

	err := repo.Create(ctx, "user-1", newRecipe)
	if err != nil {
		t.Fatalf("unexpected error on create: %v", err)
	}

	// 検証
	recipe, err := repo.FindByID(ctx, recipeId)
	if err != nil {
		t.Fatalf("unexpected error on find: %v", err)
	}
	if recipe.RecipeID != recipeId {
		t.Errorf("unexpected recipe id: %v", recipe.RecipeID)
	}
	if recipe.Title != "新規レシピ" {
		t.Errorf("unexpected title: %v", recipe.Title)
	}
	if len(recipe.IngredientGroups) != 1 {
		t.Errorf("unexpected group count: %v", len(recipe.IngredientGroups))
	}
	if len(recipe.IngredientGroups[0].Ingredients) != 1 {
		t.Errorf("unexpected ingredient count: %v", len(recipe.IngredientGroups[0].Ingredients))
	}
	if recipe.IngredientGroups[0].Ingredients[0].IngredientName != "小麦粉" {
		t.Errorf("unexpected ingredient name: %v", recipe.IngredientGroups[0].Ingredients[0].IngredientName)
	}
	if recipe.IngredientGroups[0].Ingredients[0].Amount == nil || *recipe.IngredientGroups[0].Ingredients[0].Amount != "100g" {
		t.Errorf("unexpected ingredient amount: %v", recipe.IngredientGroups[0].Ingredients[0].Amount)
	}
}

func strPtr(s string) *string {
	return &s
}
