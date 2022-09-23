package service

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/hex"
	"tepusquet/config"
	"tepusquet/model"
)

func GetCredentialForUser(userID string) model.UserCredential {
	var cred model.UserCredential
	result := DB.Where("user_id = ?", userID).Find(&cred)
	if result.Error != nil {
	}
	if cred.Username != "" && cred.Password != "" {
		// First decrypt using project key
		decryptedUsername, err := DecryptCredential([]byte(config.CredEncryptionKey), []byte(cred.Username))
		if err != nil {
			println(err)
		}
		decryptedPassword, err := DecryptCredential([]byte(config.CredEncryptionKey), []byte(cred.Password))
		if err != nil {
			println(err)
		}
		// Second decrypt using user generated key
		decryptedUsername2, err := DecryptCredential([]byte(cred.EncryptionKey), decryptedUsername)
		if err != nil {
			println(err)
		}
		decryptedPassword2, err := DecryptCredential([]byte(cred.EncryptionKey), decryptedPassword)
		if err != nil {
			println(err)
		}
		cred.Username = string(decryptedUsername2)
		cred.Password = string(decryptedPassword2)
	}
	return cred
}

func SetCredentialForUser(cred model.UserCredential) error {
	// Delete existing credential
	DB.Where("user_id = ?", cred.UserID).Delete(&model.UserCredential{})
	// First encrypt using user generated key
	encryptedUsername, err := EncryptCredential([]byte(cred.EncryptionKey), []byte(cred.Username))
	if err != nil {
		println(err)
	}
	encryptedPassword, err := EncryptCredential([]byte(cred.EncryptionKey), []byte(cred.Password))
	if err != nil {
		println(err)
	}
	// Second encrypt using project key
	encryptedUsername2, err := EncryptCredential([]byte(config.CredEncryptionKey), encryptedUsername)
	if err != nil {
		println(err)
	}
	encryptedPassword2, err := EncryptCredential([]byte(config.CredEncryptionKey), encryptedPassword)
	if err != nil {
		println(err)
	}
	cred.Username = hex.EncodeToString(encryptedUsername2)
	cred.Password = hex.EncodeToString(encryptedPassword2)
	if result := DB.Create(&cred); result.Error != nil {
		return result.Error
	}
	return nil
}

func EncryptCredential(key []byte, data []byte) ([]byte, error) {
	blockCipher, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	gcm, err := cipher.NewGCM(blockCipher)
	if err != nil {
		return nil, err
	}
	nonce := make([]byte, gcm.NonceSize())
	if _, err = rand.Read(nonce); err != nil {
		return nil, err
	}
	ciphertext := gcm.Seal(nonce, nonce, data, nil)
	return ciphertext, nil
}

func DecryptCredential(key []byte, data []byte) ([]byte, error) {
	blockCipher, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	gcm, err := cipher.NewGCM(blockCipher)
	if err != nil {
		return nil, err
	}
	nonce, ciphertext := data[:gcm.NonceSize()], data[gcm.NonceSize():]
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return nil, err
	}
	return plaintext, nil
}
