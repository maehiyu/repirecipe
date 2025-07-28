package controller_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"

	"repirecipe/controller"
	"repirecipe/entity"
	"repirecipe/usecase"
)

// モックリポジトリ
type mockRepo struct {
	CreateCalled bool
	UpdateCalled bool
	DeleteCalled bool
}

func (m *mockRepo) FindByID(ctx context.Context, id string) (*entity.RecipeDetail, error) {
	return nil, nil
}
func (m *mockRepo) FindAllByUserID(ctx context.Context, userId string) ([]*entity.RecipeSummary, error) {
	return nil, nil
}
func (m *mockRepo) Create(ctx context.Context, userId string, recipe *entity.RecipeDetail) error {
	m.CreateCalled = true
	return nil
}
func (m *mockRepo) Update(ctx context.Context, recipe *entity.RecipeDetail) error {
	m.UpdateCalled = true
	return nil
}
func (m *mockRepo) Delete(ctx context.Context, recipeId string) error {
	m.DeleteCalled = true
	return nil
}
func (m *mockRepo) DeleteAllByUserID(ctx context.Context, userId string) error {
	return nil
}
func (m *mockRepo) GetRecipesByIngredientVectors(ctx context.Context, userId string, ingredientVecs [][]float32) ([]*entity.RecipeSummary, error) {
	return []*entity.RecipeSummary{}, nil
}
func (m *mockRepo) GetRecipesByTitleVector(ctx context.Context, userId string, titleVec []float32) ([]*entity.RecipeSummary, error) {
	return []*entity.RecipeSummary{}, nil
}

type mockScraper struct{}

func (m *mockScraper) ScrapeText(ctx context.Context, input string) (string, error) {
	return "テスト用レシピテキスト", nil
}

type mockLLMClient struct{}

func (m *mockLLMClient) GenerateRecipeDetail(ctx context.Context, text string) (*entity.RecipeDetail, error) {
	return &entity.RecipeDetail{
		Title: "テストレシピ",
		IngredientGroups: []entity.IngredientGroup{
			{
				Title: ptr("材料"),
				Ingredients: []entity.Ingredient{
					{IngredientName: "鶏もも肉", Amount: ptr("300g")},
				},
			},
		},
	}, nil
}

// Add EmbedText to satisfy usecase.LLMClient interface
func (m *mockLLMClient) EmbedText(ctx context.Context, text string) ([]float32, error) {
	return []float32{0.1, 0.2, 0.3}, nil
}

func ptr(s string) *string { return &s }

func TestCreateRecipe(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mock := &mockRepo{}
	uc := usecase.NewRecipeUsecase(mock, nil, nil) // Scraper, LLMClientをnilで追加
	ctrl := controller.NewRecipeController(uc)
	r := gin.New()
	r.POST("/recipes", func(c *gin.Context) { c.Set("userId", "user-1"); ctrl.CreateRecipe(c) })

	body := entity.RecipeDetail{RecipeID: "test-id", Title: "test"}
	jsonBody, _ := json.Marshal(body)
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/recipes", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusCreated, w.Code)
	assert.True(t, mock.CreateCalled)
}

func TestUpdateRecipe(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mock := &mockRepo{}
	uc := usecase.NewRecipeUsecase(mock, nil, nil) // Scraper, LLMClientをnilで追加
	ctrl := controller.NewRecipeController(uc)
	r := gin.New()
	r.PUT("/recipes/:id", func(c *gin.Context) { ctrl.UpdateRecipe(c) })

	body := entity.RecipeDetail{Title: "updated"}
	jsonBody, _ := json.Marshal(body)
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("PUT", "/recipes/test-id", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
	assert.True(t, mock.UpdateCalled)
}

func TestDeleteRecipe(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mock := &mockRepo{}
	uc := usecase.NewRecipeUsecase(mock, nil, nil) // Scraper, LLMClientをnilで追加
	ctrl := controller.NewRecipeController(uc)
	r := gin.New()
	r.DELETE("/recipes/:id", func(c *gin.Context) { ctrl.DeleteRecipe(c) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("DELETE", "/recipes/test-id", nil)

	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
	assert.True(t, mock.DeleteCalled)
}

func TestFetchRecipe(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mock := &mockRepo{}
	scraper := &mockScraper{}
	llm := &mockLLMClient{}
	uc := usecase.NewRecipeUsecase(mock, scraper, llm)
	ctrl := controller.NewRecipeController(uc)
	r := gin.New()
	r.POST("/recipes/fetch", func(c *gin.Context) { c.Set("userId", "user-1"); ctrl.FetchRecipe(c) })

	form := "url=https://example.com/recipe"
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/recipes/fetch", bytes.NewBufferString(form))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusCreated, w.Code)
	assert.True(t, mock.CreateCalled)
}
