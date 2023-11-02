package service

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"io"
	"tepusquet/config"
	"tepusquet/model"
	"tepusquet/utils"
)

func GetCredentialForUser(userID string, deviceKey string) model.UserCredential {
	var cred model.UserCredential
	result := DB.Where("user_id = ?", userID).Find(&cred)
	if result.Error != nil {
	}
	if cred.Username != "" && cred.Password != "" {
		// First decrypt using project key
		decryptedUsername, err := DecryptAES256GCM(config.CredEncryptionKey, cred.Username)
		if err != nil {
			utils.SugarLogger.Errorln(err)
			cred.Username = "error"
			return cred
		}
		decryptedPassword, err := DecryptAES256GCM(config.CredEncryptionKey, cred.Password)
		if err != nil {
			utils.SugarLogger.Errorln(err)
			cred.Username = "error"
			return cred
		}
		// Second decrypt using user generated key
		decryptedUsername2, err := DecryptAES256GCM(deviceKey, decryptedUsername)
		if err != nil {
			utils.SugarLogger.Errorln(err)
			cred.Username = "error"
			return cred
		}
		decryptedPassword2, err := DecryptAES256GCM(deviceKey, decryptedPassword)
		if err != nil {
			utils.SugarLogger.Errorln(err)
			cred.Username = "error"
			return cred
		}
		cred.Username = decryptedUsername2
		cred.Password = decryptedPassword2
	}
	return cred
}

func SetCredentialForUser(cred model.UserCredential) error {
	// Delete existing credential
	DeleteCredentialForUser(cred.UserID)
	// Credentials come encrypted using user generated key
	// Second encrypt using project key
	encryptedUsername2, err := EncryptAES256GCM(config.CredEncryptionKey, cred.Username)
	if err != nil {
		utils.SugarLogger.Errorln(err)
		return err
	}
	encryptedPassword2, err := EncryptAES256GCM(config.CredEncryptionKey, cred.Password)
	if err != nil {
		utils.SugarLogger.Errorln(err)
		return err
	}
	cred.Username = encryptedUsername2
	cred.Password = encryptedPassword2
	if result := DB.Create(&cred); result.Error != nil {
		return result.Error
	}
	return nil
}

func DeleteCredentialForUser(userID string) {
	DB.Where("user_id = ?", userID).Delete(&model.UserCredential{})
}

func EncryptAES256GCM(key string, plaintext string) (string, error) {
	println("Encrypting " + plaintext + " with key " + key)
	if len(key) != 32 {
		return "", fmt.Errorf("key length must be 32 characters")
	}
	// Generate a random nonce (IV) of 12 bytes
	nonce := make([]byte, 12)
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}
	// Create a new AES cipher block
	block, err := aes.NewCipher([]byte(key))
	if err != nil {
		return "", err
	}
	// Create a GCM mode cipher
	aesGCM, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}
	// Encrypt the plaintext
	ciphertext := aesGCM.Seal(nil, nonce, []byte(plaintext), nil)
	// Combine the nonce and ciphertext for storage
	encryptedData := append(nonce, ciphertext...)
	// Convert the result to a hex-encoded string
	encryptedHex := hex.EncodeToString(encryptedData)
	return encryptedHex, nil
}

func DecryptAES256GCM(key string, encryptedHex string) (string, error) {
	if len(key) != 32 {
		return "", fmt.Errorf("key length must be 32 characters")
	}
	// Decode the hex-encoded input into bytes
	encryptedData, err := hex.DecodeString(encryptedHex)
	if err != nil {
		return "", err
	}
	// Extract the nonce (first 12 bytes) and ciphertext
	nonce := encryptedData[:12]
	ciphertext := encryptedData[12:]
	// Create a new AES cipher block
	block, err := aes.NewCipher([]byte(key))
	if err != nil {
		return "", err
	}
	// Create a GCM mode cipher
	aesGCM, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}
	// Decrypt the ciphertext
	plaintext, err := aesGCM.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return "", err
	}
	return string(plaintext), nil
}
