> data Tree v =
>     Empty
>   | Node v (Tree v) (Tree v)
>   deriving (Show)

> findT :: Ord v => v -> Tree v -> Maybe v
> findT _ Empty = Nothing
> findT v (Node val left right) =
>   if val == v then
>     Just val
>   else if v < val then
>     findT v left
>   else
>     findT v right


> instance Functor Tree where 
> 	fmap f Empty = Empty
>	fmap f (Node val left right) =  Node (f val) (fmap f left) (fmap f right) 


Your job is to add support for fmap to this tree, so that the following call works:
fmap (+1) (Node 3 (Node 1 Empty Empty) (Node 7 (Node 4 Empty Empty) Empty))

Checking Law 1:
x = (Node 3 (Node 1 Empty Empty) (Node 7 (Node 4 Empty Empty) Empty))
fmap id x
Checking Law 2:
(fmap (+1) . fmap (+1)) x 
fmap ((+1).(+1)) x



% > data Val v = NothingToSee
% >		| VInt v
% > 	deriving (Show)

% > instance Functor Val where
% >	fmap f NothingToSee = NothingToSee
% > fmap f (VInt a) = VInt (f a)

% Checking Law 1:
% x = (VInt 3)
% fmap id x
% Checking Law 2:
% (fmap (+1) . fmap (+1)) x 
% fmap ((+1).(+1)) x



