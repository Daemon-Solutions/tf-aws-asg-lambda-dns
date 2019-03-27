package test

import (
	"strconv"
	"testing"

	"github.com/stretchr/testify/require"
)

func stringToIntE(t *testing.T, s string) (int, error) {
	i, err := strconv.Atoi(s)
	if err != nil {
		return 0, err
	}
	return i, err

}

func stringToInt(t *testing.T, s string) int {
	i, err := stringToIntE(t, s)
	require.NoError(t, err)
	return i
}
