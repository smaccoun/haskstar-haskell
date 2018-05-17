{-# LANGUAGE TemplateHaskell #-}

module Api.Endpoints.BlogPost where

import           Api.Resource
import           App
import           AppPrelude
import           Data.Aeson
import           Data.Time.Clock          (getCurrentTime)
import           Data.UUID                (UUID)
import           Database.Beam
import           Database.Beam.Postgres
import           Database.Crud
import           Database.MasterEntity
import           Database.Schema
import           Database.Tables.BlogPost
import           Database.Transaction
import           Models.User
import           Servant


type BlogPostViewAPI = RResourceAPI "blogPost" BlogPostEntity UUID

blogPostViewServer :: ServerT BlogPostViewAPI AppM
blogPostViewServer = rResourceServer getBlogPosts getBlogPost

getBlogPosts :: AppM [BlogPostEntity]
getBlogPosts = do
  getEntities blogPostTable

getBlogPost :: UUID -> AppM BlogPostEntity
getBlogPost blogPostId' = do
  getEntity blogPostTable blogPostId'

type BlogPostMutateAPI = "blogPost" :>
  ( ReqBody '[JSON] BlogPost :> Post '[JSON] BlogPost
  :<|> (
          Capture "uuid" UUID
        :> ReqBody '[JSON] BlogPost :> Patch '[JSON] BlogPostEntity
        )
  )

instance FromJSON BlogPost

blogPostMutateServer ::
      UserResponse
  -> ServerT BlogPostMutateAPI AppM
blogPostMutateServer _ =
       createBlogPost
  :<|> updateBlogPost

createBlogPost :: BlogPost -> AppM BlogPost
createBlogPost bpr = do
  now <- liftIO getCurrentTime
  _ <- runInsertM $ insertStmt now
  return bpr
  where
    insertStmt now = insert blogPostTable $
        insertExpressions
          [ AppEntity
              default_
              (BlogPostBaseT (val_ $ title bpr) (val_ $ content bpr))
              default_
              (val_ now)
          ]


updateBlogPost :: UUID -> BlogPost -> AppM BlogPostEntity
updateBlogPost blogPostId' bpr = do
  runSqlM blogUpdateQ
  where
    blogUpdateQ :: Pg BlogPostEntity
    blogUpdateQ = do
      Just bp <- runSelectReturningOne $
              lookup_ blogPostTable (MyAppKey blogPostId')
      _ <- runUpdate $
            save (blogPostTable)
                (bp { _table = bpr })

      return bp

