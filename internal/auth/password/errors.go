package password

import "errors"

var (
	// ErrTooShort results from attempting to set a password which is to
	// short.
	ErrTooShort = errors.New("password to short")

	// ErrUnsupportedConfiguration results from attempting to perform an
	// operation that sets a password configuration to an unsupported type.
	ErrUnsupportedConfiguration = errors.New("unsupported configuration")

	// ErrInvalidConfiguration results from attempting to perform an
	// operation that sets a password configuration with invalid settings.
	ErrInvalidConfiguration = errors.New("invalid configuration")
)