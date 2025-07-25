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

func TestCreateRecipe(t *testing.T) {
	gin.SetMode(gin.TestMode)
	mock := &mockRepo{}
	uc := usecase.NewRecipeUsecase(mock)
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
	uc := usecase.NewRecipeUsecase(mock)
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
	uc := usecase.NewRecipeUsecase(mock)
	ctrl := controller.NewRecipeController(uc)
	r := gin.New()
	r.DELETE("/recipes/:id", func(c *gin.Context) { ctrl.DeleteRecipe(c) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("DELETE", "/recipes/test-id", nil)

	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
	assert.True(t, mock.DeleteCalled)
}
