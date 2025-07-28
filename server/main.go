package main

import (
	"log"
	"os"

	"repirecipe/controller"
	"repirecipe/llmclient"
	"repirecipe/repository"
	"repirecipe/scraper"
	"repirecipe/usecase"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
)

// --- APIエンドポイント一覧 ---
// **GET**    /recipes                  : レシピを一括取得
// **POST**   /recipes                  : レシピ新規作成
// **PUT**    /recipes                  : レシピを更新
// **GET**    /recipes/search           : レシピを検索
// **GET**    /recipes/:id              : レシピ取得
// **POST**   /recipes/fetch            : 外部情報(URL)からレシピを新規作成
// **POST**   /recipes/fetch/instagram  : Instagramからレシピ取得
// **DELETE** /account                  : アカウントに基づくデータの削除

func testUserMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Set("userId", "user-1")
		c.Next()
	}
}

func main() {
	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbUser := os.Getenv("DB_USER")
	dbPassword := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")

	repo, err := repository.NewPostgresRepository(dbHost, dbPort, dbUser, dbPassword, dbName)
	if err != nil {
		log.Fatal(err)
	}

	// ScraperとLLMClientをDIで渡す
	scraper := &scraper.RecipeScraper{}
	llmClient := llmclient.NewLLMClient() // 実装に合わせて適切に初期化

	u := usecase.NewRecipeUsecase(repo, scraper, llmClient)
	c := controller.NewRecipeController(u)

	r := gin.Default()
	protected := r.Group("/")
	protected.Use(testUserMiddleware()) // テスト用userId注入

	protected.GET("/recipes", c.GetRecipes)
	protected.POST("/recipes", c.CreateRecipe)
	protected.PUT("/recipes", c.UpdateRecipe)
	protected.GET("/recipes/search", c.SearchRecipes)
	protected.GET("/recipes/:id", c.GetRecipe)
	protected.DELETE("/recipes/:id", c.DeleteRecipe)
	protected.POST("/recipes/fetch", c.FetchRecipe)
	protected.DELETE("/account", c.DeleteAccount)

	r.Run(":8080")
}
