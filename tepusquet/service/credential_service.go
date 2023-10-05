package service

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/hex"
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
		// First decode string from db to bytes
		println("cred.Username: " + cred.Username)
		println("cred.Password: " + cred.Password)
		encryptedUsername, err := hex.DecodeString(cred.Username)
		if err != nil {
			utils.SugarLogger.Errorln(err)
		}
		encryptedPassword, err := hex.DecodeString(cred.Password)
		if err != nil {
			utils.SugarLogger.Errorln(err)
		}
		// First decrypt using project key
		decryptedUsername, err := DecryptCredential([]byte(config.CredEncryptionKey), encryptedUsername)
		if err != nil {
			utils.SugarLogger.Errorln(err)
		}
		decryptedPassword, err := DecryptCredential([]byte(config.CredEncryptionKey), encryptedPassword)
		if err != nil {
			utils.SugarLogger.Errorln(err)
		}
		println("decryptedUsername: " + string(decryptedUsername))
		println("decryptedPassword: " + string(decryptedPassword))
		// Second decrypt using user generated key
		decryptedUsername2, err := DecryptCredential([]byte(deviceKey), decryptedUsername)
		if err != nil {
			utils.SugarLogger.Errorln(err)
		}
		decryptedPassword2, err := DecryptCredential([]byte(deviceKey), decryptedPassword)
		if err != nil {
			utils.SugarLogger.Errorln(err)
		}
		println("decryptedUsername2: " + string(decryptedUsername2))
		println("decryptedPassword2: " + string(decryptedPassword2))
		cred.Username = string(decryptedUsername2)
		cred.Password = string(decryptedPassword2)
	}
	return cred
}

func SetCredentialForUser(cred model.UserCredential) error {
	// Delete existing credential
	DB.Where("user_id = ?", cred.UserID).Delete(&model.UserCredential{})
	// Credentials come encrypted using user generated key
	// Second encrypt using project key
	encryptedUsername2, err := EncryptCredential([]byte(config.CredEncryptionKey), []byte(cred.Username))
	if err != nil {
		utils.SugarLogger.Errorln(err)
	}
	encryptedPassword2, err := EncryptCredential([]byte(config.CredEncryptionKey), []byte(cred.Password))
	if err != nil {
		utils.SugarLogger.Errorln(err)
	}
	cred.Username = hex.EncodeToString(encryptedUsername2)
	cred.Password = hex.EncodeToString(encryptedPassword2)
	if result := DB.Create(&cred); result.Error != nil {
		return result.Error
	}
	return nil
}

func DeleteCredentialForUser(userID string) {
	DB.Where("user_id = ?", userID).Delete(&model.UserCredential{})
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
