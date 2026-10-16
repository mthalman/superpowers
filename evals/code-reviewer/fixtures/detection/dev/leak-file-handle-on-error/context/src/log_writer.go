// src/log_writer.go — appends a line to a log file.

package logwriter

import (
	"fmt"
	"os"
)

// AppendLine opens the log file and writes one line. On any error in the
// write, the function returns the error to the caller.
func AppendLine(path string, line string) error {
	f, err := os.OpenFile(path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	if _, err := f.WriteString(line + "\n"); err != nil {
		return fmt.Errorf("write: %w", err)
	}
	return f.Close()
}
