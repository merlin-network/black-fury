package keeper

import (
	"github.com/merlin-network/black/v6/x/govshuttle/types"
)

var _ types.QueryServer = Keeper{}
