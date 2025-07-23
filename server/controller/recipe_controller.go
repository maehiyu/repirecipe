package controller

import (
	"log"
	"net/http"

	"repirecipe/entity"
	"repirecipe/usecase"

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
