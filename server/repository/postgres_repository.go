package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"log"
	"repirecipe/entity"
	"repirecipe/usecase"
	"sort"
	"time"

	"github.com/pgvector/pgvector-go"
	"github.com/redis/go-redis/v9"
)

type PostgresRepository struct {
	db    *sql.DB
	cache *redis.Client
}

func NewPostgresRepository(host, port, user, password, dbname string) (usecase.Repository, error) {
	dsn := "host=" + host + " port=" + port + " user=" + user + " password=" + password + " dbname=" + dbname + " sslmode=disable"
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, err
	}
	// Redisクライアントの初期化（docker-composeのサービス名を利用）
	cache := redis.NewClient(&redis.Options{
		Addr: "redis:6379",
	})
	return &PostgresRepository{db: db, cache: cache}, nil
}

func (r *PostgresRepository) FindByID(ctx context.Context, id string) (*entity.RecipeDetail, error) {
	cacheKey := "recipe:" + id
	val, err := r.cache.Get(ctx, cacheKey).Result()
	if err == nil && val != "" {
		var rec entity.RecipeDetail
		if err := json.Unmarshal([]byte(val), &rec); err == nil {
			return &rec, nil
		}
	}

	row := r.db.QueryRowContext(ctx, `
        SELECT recipe_id, title, thumbnail_url, media_url, memo, created_at, last_cooked_at
        FROM recipes
        WHERE recipe_id = $1
    `, id)
	var rec entity.RecipeDetail
	err = row.Scan(&rec.RecipeID, &rec.Title, &rec.ThumbnailURL, &rec.MediaURL, &rec.Memo, &rec.CreatedAt, &rec.LastCookedAt)
	if err != nil {
		log.Println("FindByID error:", err)
		return nil, err
	}

	// グループ取得
	groupRows, err := r.db.QueryContext(ctx, `
        SELECT group_id, title, order_num
        FROM ingredient_groups
        WHERE recipe_id = $1
        ORDER BY order_num ASC
    `, rec.RecipeID)
	if err != nil {
		log.Println("FindByID ingredient_groups error:", err)
		return nil, err
	}
	defer groupRows.Close()

	var groups []entity.IngredientGroup
	for groupRows.Next() {
		var group entity.IngredientGroup
		err := groupRows.Scan(&group.GroupID, &group.Title, &group.OrderNum)
		if err != nil {
			return nil, err
		}
		// 材料取得
		ingRows, err := r.db.QueryContext(ctx, `
    SELECT id, ingredient_name, ingredient_amount, order_num, ingredient_vector
    FROM ingredients
    WHERE group_id = $1
    ORDER BY order_num ASC
`, group.GroupID)
		if err != nil {
			return nil, err
		}
		var ingredients []entity.Ingredient
		for ingRows.Next() {
			var ing entity.Ingredient
			var vec pgvector.Vector
			if err := ingRows.Scan(&ing.ID, &ing.IngredientName, &ing.Amount, &ing.OrderNum, &vec); err != nil {
				ingRows.Close()
				return nil, err
			}
			ing.IngredientVector = vec.Slice()
			ingredients = append(ingredients, ing)
		}
		ingRows.Close()
		group.Ingredients = ingredients
		groups = append(groups, group)
	}
	rec.IngredientGroups = groups

	b, _ := json.Marshal(rec)
	r.cache.Set(ctx, cacheKey, b, 10*time.Minute)
	return &rec, nil
}

func (r *PostgresRepository) FindAllByUserID(ctx context.Context, userId string) ([]*entity.RecipeSummary, error) {
	cacheKey := "user_recipes:" + userId
	val, err := r.cache.Get(ctx, cacheKey).Result()
	if err == nil && val != "" {
		var recipes []*entity.RecipeSummary
		if err := json.Unmarshal([]byte(val), &recipes); err == nil {
			return recipes, nil
		}
	}

	rows, err := r.db.QueryContext(ctx, `
        SELECT recipe_id, title, thumbnail_url, created_at
        FROM recipes
        WHERE user_id = $1
        ORDER BY created_at DESC
    `, userId)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var recipes []*entity.RecipeSummary
	for rows.Next() {
		var recipe entity.RecipeSummary
		err := rows.Scan(&recipe.RecipeID, &recipe.Title, &recipe.ThumbnailURL, &recipe.CreatedAt)
		if err != nil {
			return nil, err
		}

		// ingredient_groupsを取得し、そのgroup_idでingredientsを取得
		groupRows, err := r.db.QueryContext(ctx, `
            SELECT group_id
            FROM ingredient_groups
            WHERE recipe_id = $1
            ORDER BY order_num ASC
        `, recipe.RecipeID)
		if err != nil {
			return nil, err
		}
		var ingredients []string
		for groupRows.Next() {
			var groupID string
			if err := groupRows.Scan(&groupID); err != nil {
				groupRows.Close()
				return nil, err
			}
			// group_idごとにingredientsを取得
			ingRows, err := r.db.QueryContext(ctx, `
                SELECT ingredient_name
                FROM ingredients
                WHERE group_id = $1
                ORDER BY order_num ASC
            `, groupID)
			if err != nil {
				groupRows.Close()
				return nil, err
			}
			for ingRows.Next() {
				var name string
				if err := ingRows.Scan(&name); err != nil {
					ingRows.Close()
					groupRows.Close()
					return nil, err
				}
				ingredients = append(ingredients, name)
			}
			ingRows.Close()
		}
		groupRows.Close()
		recipe.IngredientsName = ingredients

		recipes = append(recipes, &recipe)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	b, _ := json.Marshal(recipes)
	r.cache.Set(ctx, cacheKey, b, 10*time.Minute)
	return recipes, nil
}

func (r *PostgresRepository) Create(ctx context.Context, userId string, recipe *entity.RecipeDetail) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() {
		if err != nil {
			tx.Rollback()
		}
	}()

	// レシピ本体を挿入
	query := `
    INSERT INTO recipes (recipe_id, user_id, title, thumbnail_url, media_url, memo, created_at, last_cooked_at, title_vector)
    VALUES ($1, $2, $3, $4, $5, $6, NOW(), $7, $8)
`
	_, err = tx.ExecContext(ctx, query,
		recipe.RecipeID,
		userId,
		recipe.Title,
		recipe.ThumbnailURL,
		recipe.MediaURL,
		recipe.Memo,
		recipe.LastCookedAt,
		pgvector.NewVector(recipe.TitleVector), // 追加
	)
	if err != nil {
		tx.Rollback()
		return err
	}

	// ingredient_groupsとingredientsを挿入
	for gi, group := range recipe.IngredientGroups {
		_, err := tx.ExecContext(ctx, `
            INSERT INTO ingredient_groups (group_id, recipe_id, title, order_num)
            VALUES ($1, $2, $3, $4)
        `, group.GroupID, recipe.RecipeID, group.Title, gi+1)
		if err != nil {
			tx.Rollback()
			return err
		}
		for ii, ing := range group.Ingredients {
			_, err := tx.ExecContext(ctx, `
                INSERT INTO ingredients (id, group_id, ingredient_name, ingredient_amount, order_num, ingredient_vector)
                VALUES ($1, $2, $3, $4, $5, $6)
            `, ing.ID, group.GroupID, ing.IngredientName, ing.Amount, ii+1, pgvector.NewVector(ing.IngredientVector))
			if err != nil {
				tx.Rollback()
				return err
			}
		}
	}

	r.cache.Del(ctx, "user_recipes:"+userId)
	return tx.Commit()
}

func (r *PostgresRepository) Update(ctx context.Context, recipe *entity.RecipeDetail) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() {
		if err != nil {
			tx.Rollback()
		}
	}()

	// レシピ本体を更新
	_, err = tx.ExecContext(ctx, `
    UPDATE recipes SET title = $1, thumbnail_url = $2, media_url = $3, memo = $4, last_cooked_at = $5, title_vector = $6
    WHERE recipe_id = $7
`,
		recipe.Title,
		recipe.ThumbnailURL,
		recipe.MediaURL,
		recipe.Memo,
		recipe.LastCookedAt,
		pgvector.NewVector(recipe.TitleVector),
		recipe.RecipeID,
	)
	if err != nil {
		tx.Rollback()
		return err
	}

	// 既存のingredient_groupsとingredientsを削除
	_, err = tx.ExecContext(ctx, `
        DELETE FROM ingredients WHERE group_id IN (SELECT group_id FROM ingredient_groups WHERE recipe_id = $1)
    `, recipe.RecipeID)
	if err != nil {
		tx.Rollback()
		return err
	}
	_, err = tx.ExecContext(ctx, `
        DELETE FROM ingredient_groups WHERE recipe_id = $1
    `, recipe.RecipeID)
	if err != nil {
		tx.Rollback()
		return err
	}

	// 新しいingredient_groupsとingredientsを挿入
	for gi, group := range recipe.IngredientGroups {
		_, err := tx.ExecContext(ctx, `
            INSERT INTO ingredient_groups (group_id, recipe_id, title, order_num)
            VALUES ($1, $2, $3, $4)
        `, group.GroupID, recipe.RecipeID, group.Title, gi+1)
		if err != nil {
			tx.Rollback()
			return err
		}
		for ii, ing := range group.Ingredients {
			_, err := tx.ExecContext(ctx, `
                INSERT INTO ingredients (id, group_id, ingredient_name, ingredient_amount, order_num)
                VALUES ($1, $2, $3, $4, $5)
            `, ing.ID, group.GroupID, ing.IngredientName, ing.Amount, ii+1)
			if err != nil {
				tx.Rollback()
				return err
			}
		}
	}

	r.cache.Del(ctx, "recipe:"+recipe.RecipeID)
	return tx.Commit()
}

func (r *PostgresRepository) Delete(ctx context.Context, userId string, recipeId string) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// userIdとrecipeIdの両方でマッチするかチェック
	var count int
	err = tx.QueryRowContext(ctx, `
        SELECT COUNT(*) FROM recipes 
        WHERE recipe_id = $1 AND user_id = $2
    `, recipeId, userId).Scan(&count)
	if err != nil {
		return err
	}
	if count == 0 {
		return errors.New("recipe not found or access denied")
	}

	// 削除処理（ingredients → ingredient_groups → recipes の順）
	_, err = tx.ExecContext(ctx, `
        DELETE FROM ingredients 
        WHERE group_id IN (SELECT group_id FROM ingredient_groups WHERE recipe_id = $1)
    `, recipeId)
	if err != nil {
		return err
	}

	_, err = tx.ExecContext(ctx, `
        DELETE FROM ingredient_groups WHERE recipe_id = $1
    `, recipeId)
	if err != nil {
		return err
	}

	_, err = tx.ExecContext(ctx, `
        DELETE FROM recipes WHERE recipe_id = $1 AND user_id = $2
    `, recipeId, userId)
	if err != nil {
		return err
	}

	// キャッシュクリア
	r.cache.Del(ctx, "recipe:"+recipeId)
	r.cache.Del(ctx, "user_recipes:"+userId)

	return tx.Commit()
}

// ユーザーに紐づく全レシピと関連データを削除する
func (r *PostgresRepository) DeleteAllByUserID(ctx context.Context, userId string) error {
	// 1. ユーザーの全レシピIDを取得
	rows, err := r.db.QueryContext(ctx, `
        SELECT recipe_id FROM recipes WHERE user_id = $1
    `, userId)
	if err != nil {
		return err
	}
	defer rows.Close()

	var recipeIDs []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return err
		}
		recipeIDs = append(recipeIDs, id)
	}

	// 2. 各レシピごとにingredients, ingredient_groups, recipesを削除
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	for _, recipeId := range recipeIDs {
		_, err := tx.ExecContext(ctx, `
            DELETE FROM ingredients WHERE group_id IN (SELECT group_id FROM ingredient_groups WHERE recipe_id = $1)
        `, recipeId)
		if err != nil {
			tx.Rollback()
			return err
		}
		_, err = tx.ExecContext(ctx, `
            DELETE FROM ingredient_groups WHERE recipe_id = $1
        `, recipeId)
		if err != nil {
			tx.Rollback()
			return err
		}
		_, err = tx.ExecContext(ctx, `
            DELETE FROM recipes WHERE recipe_id = $1
        `, recipeId)
		if err != nil {
			tx.Rollback()
			return err
		}
		// キャッシュも削除
		r.cache.Del(ctx, "recipe:"+recipeId)
	}
	// ユーザーのレシピ一覧キャッシュも削除
	r.cache.Del(ctx, "user_recipes:"+userId)

	return tx.Commit()
}

func (r *PostgresRepository) Search(ctx context.Context, query string) ([]*entity.RecipeSummary, error) {
	// 実装例
	return nil, nil
}

// 材料ベクトルでの検索を追加
func (r *PostgresRepository) GetRecipesByIngredientVectors(ctx context.Context, userId string, ingredientVecs [][]float32) ([]*entity.RecipeSummary, error) {
	type scoredRecipe struct {
		*entity.RecipeSummary
		totalScore float64
		matchCount int
		bestScore  float64
	}
	scoreMap := make(map[string]*scoredRecipe)

	for _, vec := range ingredientVecs {
		vecPg := pgvector.NewVector(vec)
		rows, err := r.db.QueryContext(ctx, `
            SELECT DISTINCT r.recipe_id, r.title, r.thumbnail_url, r.created_at,
                   MIN(i.ingredient_vector <-> $2) AS score
            FROM recipes r
            JOIN ingredient_groups ig ON r.recipe_id = ig.recipe_id  
            JOIN ingredients i ON ig.group_id = i.group_id
            WHERE r.user_id = $1 AND i.ingredient_vector IS NOT NULL
            GROUP BY r.recipe_id, r.title, r.thumbnail_url, r.created_at
            ORDER BY score
            LIMIT 10
        `, userId, vecPg)
		if err != nil {
			return nil, err
		}
		for rows.Next() {
			var rec entity.RecipeSummary
			var score float64
			if err := rows.Scan(&rec.RecipeID, &rec.Title, &rec.ThumbnailURL, &rec.CreatedAt, &score); err != nil {
				rows.Close()
				return nil, err
			}
			if existing, ok := scoreMap[rec.RecipeID]; ok {
				// 既存レシピの場合：マッチ数を増やし、スコアを更新
				existing.matchCount++
				existing.totalScore += score
				if score < existing.bestScore {
					existing.bestScore = score
				}
			} else {
				// 新しいレシピの場合
				scoreMap[rec.RecipeID] = &scoredRecipe{
					RecipeSummary: &rec,
					totalScore:    score,
					matchCount:    1,
					bestScore:     score,
				}
			}
		}
		rows.Close()
	}

	// 最終スコア計算：マッチ数ボーナス + 平均スコア
	var scoredList []*scoredRecipe
	for _, v := range scoreMap {
		// マッチ数が多いほど良いスコア（例：マッチ数ボーナス）
		matchBonus := float64(v.matchCount) * 0.1
		avgScore := v.totalScore / float64(v.matchCount)
		v.totalScore = avgScore - matchBonus // ボーナス分を引く（小さいほど良い）
		scoredList = append(scoredList, v)
	}

	// 最終スコア順でソート
	sort.Slice(scoredList, func(i, j int) bool {
		return scoredList[i].totalScore < scoredList[j].totalScore
	})

	// 結果を []*entity.RecipeSummary に変換
	var results []*entity.RecipeSummary
	for _, v := range scoredList {
		results = append(results, v.RecipeSummary)
	}
	return results, nil
}

// タイトルのベクトル検索
func (r *PostgresRepository) GetRecipesByTitleVector(ctx context.Context, userId string, titleVec []float32) ([]*entity.RecipeSummary, error) {
	titleVecPg := pgvector.NewVector(titleVec)
	rows, err := r.db.QueryContext(ctx, `
        SELECT recipe_id, title, thumbnail_url, created_at
        FROM recipes
        WHERE user_id = $1
        ORDER BY title_vector <-> $2
        LIMIT 20
    `, userId, titleVecPg)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []*entity.RecipeSummary
	for rows.Next() {
		var rec entity.RecipeSummary
		err := rows.Scan(&rec.RecipeID, &rec.Title, &rec.ThumbnailURL, &rec.CreatedAt)
		if err != nil {
			return nil, err
		}
		results = append(results, &rec)
	}
	return results, nil
}
