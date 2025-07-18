package repository

import (
	"context"
	"database/sql"
	"log"
	"repirecipe/entity"
	"repirecipe/usecase"

	"github.com/redis/go-redis/v9"
)

// usecase.RecipeRepository を実装
type recipeRepository struct {
	db    *sql.DB
	cache *redis.Client
}

func NewPostgresRepository(host, port, user, password, dbname string) (usecase.RecipeRepository, error) {
	dsn := "host=" + host + " port=" + port + " user=" + user + " password=" + password + " dbname=" + dbname + " sslmode=disable"
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, err
	}
	// Redisクライアントの初期化（docker-composeのサービス名を利用）
	cache := redis.NewClient(&redis.Options{
		Addr: "redis:6379",
	})
	return &recipeRepository{db: db, cache: cache}, nil
}

func (r *recipeRepository) FindByID(ctx context.Context, id string) (*entity.RecipeDetail, error) {
	row := r.db.QueryRowContext(ctx, `
        SELECT recipe_id, title, thumbnail_url, video_url, memo, created_at, last_cooked_at
        FROM recipes
        WHERE recipe_id = $1
    `, id)
	var rec entity.RecipeDetail
	err := row.Scan(&rec.RecipeID, &rec.Title, &rec.ThumbnailURL, &rec.VideoURL, &rec.Memo, &rec.CreatedAt, &rec.LastCookedAt)
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
            SELECT id, ingredient_name, ingredient_amount, order_num
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
			if err := ingRows.Scan(&ing.ID, &ing.IngredientName, &ing.Amount, &ing.OrderNum); err != nil {
				ingRows.Close()
				return nil, err
			}
			ingredients = append(ingredients, ing)
		}
		ingRows.Close()
		group.Ingredients = ingredients
		groups = append(groups, group)
	}
	rec.IngredientGroups = groups

	return &rec, nil
}

func (r *recipeRepository) FindAllByUserID(ctx context.Context, userId string) ([]*entity.RecipeSummary, error) {
	rows, err := r.db.QueryContext(ctx, `
        SELECT recipe_id, title, thumbnail_url, created_at
        FROM recipes
        WHERE user_id = $1
        ORDER BY created_at DESC
    `, userId)
	if err != nil {
		log.Println("FindAll error:", err)
		return nil, err
	}
	defer rows.Close()

	var recipes []*entity.RecipeSummary
	for rows.Next() {
		var rec entity.RecipeSummary
		err := rows.Scan(&rec.RecipeID, &rec.Title, &rec.ThumbnailURL, &rec.CreatedAt)
		if err != nil {
			return nil, err
		}

		// ingredient_groupsを取得し、そのgroup_idでingredientsを取得
		groupRows, err := r.db.QueryContext(ctx, `
            SELECT group_id
            FROM ingredient_groups
            WHERE recipe_id = $1
            ORDER BY order_num ASC
        `, rec.RecipeID)
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
		rec.IngredientsName = ingredients

		recipes = append(recipes, &rec)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return recipes, nil
}

func (r *recipeRepository) Create(ctx context.Context, userId string, recipe *entity.RecipeDetail) error {
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
        INSERT INTO recipes (recipe_id, user_id, title, thumbnail_url, video_url, memo, created_at, last_cooked_at)
        VALUES ($1, $2, $3, $4, $5, $6, NOW(), $7)
    `
	_, err = tx.ExecContext(ctx, query,
		recipe.RecipeID,
		userId,
		recipe.Title,
		recipe.ThumbnailURL,
		recipe.VideoURL,
		recipe.Memo,
		recipe.LastCookedAt,
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
                INSERT INTO ingredients (id, group_id, ingredient_name, ingredient_amount, order_num)
                VALUES ($1, $2, $3, $4, $5)
            `, ing.ID, group.GroupID, ing.IngredientName, ing.Amount, ii+1)
			if err != nil {
				tx.Rollback()
				return err
			}
		}
	}

	return tx.Commit()
}

func (r *recipeRepository) Update(ctx context.Context, recipe *entity.RecipeDetail) error {
	// 実装例
	return nil
}

func (r *recipeRepository) Search(ctx context.Context, query string) ([]*entity.RecipeSummary, error) {
	// 実装例
	return nil, nil
}
