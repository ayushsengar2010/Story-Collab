package utils

import "golang.org/x/crypto/bcrypt"

func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	if err != nil {
		return "", err
	}
	return string(bytes), err
}

func Checkpass(password, hashedpassword string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hashedpassword), []byte(password))
	return err == nil
}
