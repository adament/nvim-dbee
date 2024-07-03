package adapters

import (
	"encoding/gob"

	"github.com/google/uuid"
	"github.com/microsoft/go-mssqldb/azuread"

	"github.com/kndndrj/nvim-dbee/dbee/core"
)

// Register client
func init() {
	_ = register(&AzureSQL{}, "azuresql")

	gob.Register(uuid.UUID{})
}

var _ core.Adapter = (*AzureSQL)(nil)

type AzureSQL struct{}

func (s *AzureSQL) Connect(url string) (core.Driver, error) {
	ss := SQLServer{}
	return ss.ConnectWithDriverName(azuread.DriverName, url)
}

func (*AzureSQL) GetHelpers(opts *core.TableOptions) map[string]string {
	s := SQLServer{}
	return s.GetHelpers(opts)
}
