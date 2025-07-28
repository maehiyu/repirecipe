package controller

import (
	"log"
	"net/http"
	"repirecipe/entity"
	"repirecipe/usecase"
	"strings"

	"github.com/gin-gonic/gin"
)

type RecipeController struct {
	Interactor *usecase.RecipeUsecase
}

func NewRecipeController(u *usecase.RecipeUsecase) *RecipeController {
	return &RecipeController{Interactor: u}
}

func getUserIDFromContext(c *gin.Context) (string, bool) {
	userIdVal, exists := c.Get("userId")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "userId not found"})
		return "", false
	}
	userId, ok := userIdVal.(string)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid userId type"})
		return "", false
	}
	return userId, true
}

func (rc *RecipeController) GetRecipes(c *gin.Context) {
	userId, ok := getUserIDFromContext(c)
	if !ok {
		return
	}
	recipes, err := rc.Interactor.GetRecipes(c.Request.Context(), userId)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get recipes"})
		log.Println("Error fetching recipes:", err)
		return
	}
	c.JSON(http.StatusOK, recipes)
}

func (rc *RecipeController) GetRecipe(c *gin.Context) {
	id := c.Param("id")
	recipe, err := rc.Interactor.GetRecipeByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		log.Println("Error fetching recipe by ID:", err)
		return
	}
	c.JSON(http.StatusOK, recipe)
}

func (rc *RecipeController) CreateRecipe(c *gin.Context) {
	userId, ok := getUserIDFromContext(c)
	if !ok {
		return
	}

	var recipe entity.RecipeDetail
	if err := c.ShouldBindJSON(&recipe); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		log.Println("Error binding JSON:", err)
		return
	}

	if err := rc.Interactor.CreateRecipe(c.Request.Context(), userId, &recipe); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		log.Println("Error creating recipe:", err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "recipe created successfully"})
}

func (rc *RecipeController) UpdateRecipe(c *gin.Context) {
	id := c.Param("id")

	var recipe entity.RecipeDetail
	if err := c.ShouldBindJSON(&recipe); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		log.Println("Error binding JSON:", err)
		return
	}
	recipe.RecipeID = id
	if err := rc.Interactor.UpdateRecipe(c.Request.Context(), &recipe); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		log.Println("Error updating recipe:", err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "recipe updated successfully"})
}

func (rc *RecipeController) DeleteRecipe(c *gin.Context) {
	id := c.Param("id")

	if err := rc.Interactor.DeleteRecipe(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		log.Println("Error deleting recipe:", err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "recipe deleted successfully"})
}

func (rc *RecipeController) FetchRecipe(c *gin.Context) {
	url := c.PostForm("url")

	recipe, err := rc.Interactor.ScrapeRecipe(c, url)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to scrape recipe"})
		log.Println("Error scraping recipe:", err)
		return
	}

	userId, ok := getUserIDFromContext(c)
	if !ok {
		return
	}

	if err := rc.Interactor.CreateRecipe(c.Request.Context(), userId, recipe); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		log.Println("Error creating recipe after scrape:", err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "recipe created successfully", "recipe": recipe})
}

// アカウント削除（ユーザーの全レシピと関連データを削除）
func (rc *RecipeController) DeleteAccount(c *gin.Context) {
	userId, ok := c.Get("userId")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "userId not found"})
		return
	}

	err := rc.Interactor.DeleteRecipesByUserID(c.Request.Context(), userId.(string))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete user recipes"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "account data deleted"})
}

func (rc *RecipeController) SearchRecipes(c *gin.Context) {
	userId, ok := getUserIDFromContext(c)
	if !ok {
		return
	}
	ingredientsParam := c.Query("ingredients")
	titleParam := c.Query("title")

	var ingredients []string
	if ingredientsParam != "" {
		ingredients = strings.Split(ingredientsParam, ",")
	}

	result, err := rc.Interactor.SearchRecipes(
		c.Request.Context(),
		userId,
		ingredients,
		titleParam,
	)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	c.JSON(200, result)
}
