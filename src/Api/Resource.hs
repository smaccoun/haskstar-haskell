{-# LANGUAGE DataKinds      #-}
{-# LANGUAGE DeriveGeneric  #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE TypeOperators  #-}

module Api.Resource where

import           AppPrelude
import           Pagination
import           Servant


type GetListAPI c a =
  QueryParam "limit" Limit
    :> QueryParam "page" Offset
    :> QueryParam "orderBy" Order
    :> Get '[JSON] (c a)

type GetItemAPI a i =
  Capture "id" i    :> Get '[JSON] a

type GetCollectionServer m c a = (Maybe Limit -> Maybe Offset -> Maybe Order -> m (c a))

{- Read API -}
type RResourceAPI (resourceName :: Symbol) c a i = resourceName :>
  (    GetListAPI c a
  :<|> GetItemAPI a i
  )

rResourceServer ::
     GetCollectionServer m c a
  -> (i -> m a)
  -> ServerT (RResourceAPI name c a i) m
rResourceServer listAs getA =
  listAs :<|> getA


{- Create/Read API -}

type CreateAPI baseEntity =
   ReqBody '[JSON] baseEntity :> Post '[JSON] ()

type CRResourceAPI (resourceName :: Symbol) c a i baseEntity = resourceName :>
  (    GetListAPI c a
  :<|> GetItemAPI a i
  :<|> CreateAPI baseEntity
  )

crResourceServer
  :: GetCollectionServer m c a
  -> (i -> m a)
  -> (baseEntity -> m ())
  -> ServerT (CRResourceAPI name c a i baseEntity) m
crResourceServer listAs getA postA =
  listAs :<|> getA :<|> postA


{- Create/Read/Update API -}
type UpdateAPI a i =
   Capture "id" i :> ReqBody '[JSON] a :> Patch '[JSON] ()

type CRUResourceAPI (resourceName :: Symbol) c a i baseEntity = resourceName :>
  (    GetListAPI c a
  :<|> GetItemAPI a i
  :<|> CreateAPI baseEntity
  :<|> UpdateAPI a i
  )

cruResourceServer
  :: GetCollectionServer m c a
  -> (i -> m a)
  -> (baseEntity -> m ())
  -> (i -> a -> m ())
  -> ServerT (CRUResourceAPI name c a i baseEntity) m
cruResourceServer listAs getA postA updateA =
  listAs :<|> getA :<|> postA :<|> updateA

{- Create/Read/Update/Delete API -}
type DeleteAPI i =
   Capture "id" i :> Delete '[JSON] ()

type CRUDResourceAPI (resourceName :: Symbol) c a i baseEntity = resourceName :>
  (    GetListAPI c a
  :<|> GetItemAPI a i
  :<|> CreateAPI baseEntity
  :<|> UpdateAPI a i
  :<|> DeleteAPI i
  )

type CRUDResourceServer name c a i baseEntity m =
     GetCollectionServer m c a
  -> (i -> m a)
  -> (baseEntity -> m ())
  -> (i -> a -> m ())
  -> (i -> m ())
  -> ServerT (CRUDResourceAPI name c a i baseEntity) m

crudResourceServer :: CRUDResourceServer name c a i baseEntity m
crudResourceServer listAs getA postA updateA deleteA =
  listAs :<|> getA :<|> postA :<|> updateA :<|> deleteA
