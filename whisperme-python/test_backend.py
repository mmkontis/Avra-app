#!/usr/bin/env python3
"""
Test script for WhisperMe Backend API
Run this to verify your backend is working correctly.
"""

import httpx
import asyncio
import json
from pathlib import Path

# Backend URL
BASE_URL = "http://localhost:8000"

async def test_backend():
    """Test all the main API endpoints"""
    
    async with httpx.AsyncClient() as client:
        print("🧪 Testing WhisperMe Backend API\n")
        
        # Test 1: Health Check
        print("1️⃣ Testing health check...")
        try:
            response = await client.get(f"{BASE_URL}/")
            if response.status_code == 200:
                print("✅ Health check passed!")
                print(f"   Response: {response.json()}")
            else:
                print(f"❌ Health check failed: {response.status_code}")
        except Exception as e:
            print(f"❌ Health check failed: {e}")
        print()
        
        # Test 2: User Registration
        print("2️⃣ Testing user registration...")
        test_device_id = "test-device-12345"
        try:
            response = await client.post(f"{BASE_URL}/register", 
                                       json={
                                           "device_id": test_device_id,
                                           "email": "test@example.com"
                                       })
            if response.status_code == 200:
                print("✅ User registration passed!")
                print(f"   Response: {response.json()}")
            else:
                print(f"❌ User registration failed: {response.status_code}")
                print(f"   Response: {response.text}")
        except Exception as e:
            print(f"❌ User registration failed: {e}")
        print()
        
        # Test 3: User Status
        print("3️⃣ Testing user status...")
        try:
            response = await client.get(f"{BASE_URL}/user/{test_device_id}/status")
            if response.status_code == 200:
                print("✅ User status passed!")
                print(f"   Response: {response.json()}")
            else:
                print(f"❌ User status failed: {response.status_code}")
                print(f"   Response: {response.text}")
        except Exception as e:
            print(f"❌ User status failed: {e}")
        print()
        
        # Test 4: Test transcription endpoint (without actual audio file)
        print("4️⃣ Testing transcription endpoint structure...")
        try:
            # This will fail without proper API key and audio file, but we can test the endpoint structure
            response = await client.post(f"{BASE_URL}/transcribe", 
                                       data={
                                           "device_id": test_device_id,
                                           "language": "auto",
                                           "model": "gpt-4o-transcribe"
                                       })
            # We expect this to fail due to missing audio file, but status code tells us about setup
            if response.status_code == 422:  # Validation error - expected
                print("✅ Transcription endpoint structure is correct!")
                print("   (Expected validation error due to missing audio file)")
            elif response.status_code == 500 and "OpenAI API key not configured" in response.text:
                print("⚠️  Transcription endpoint works, but OpenAI API key not configured")
                print("   Add your OPENAI_API_KEY to the .env file")
            else:
                print(f"❓ Transcription endpoint returned: {response.status_code}")
                print(f"   Response: {response.text}")
        except Exception as e:
            print(f"❌ Transcription endpoint test failed: {e}")
        print()
        
        # Test 5: Upgrade user
        print("5️⃣ Testing user upgrade...")
        try:
            response = await client.post(f"{BASE_URL}/upgrade/{test_device_id}?tier=premium")
            if response.status_code == 200:
                print("✅ User upgrade passed!")
                print(f"   Response: {response.json()}")
            else:
                print(f"❌ User upgrade failed: {response.status_code}")
                print(f"   Response: {response.text}")
        except Exception as e:
            print(f"❌ User upgrade failed: {e}")
        print()
        
        print("🎉 Backend API testing completed!")
        print("\n📋 Next Steps:")
        print("1. Make sure your .env file has a valid OPENAI_API_KEY")
        print("2. Test with a real audio file using curl or your Swift app")
        print("3. Check the API documentation at http://localhost:8000/docs")

if __name__ == "__main__":
    print("Starting backend API tests...")
    print("Make sure the backend is running with: uv run main.py")
    print()
    
    try:
        asyncio.run(test_backend())
    except KeyboardInterrupt:
        print("\n⏹️  Test interrupted by user")
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        print("Make sure the backend server is running!") 