# GROQ API KEY SETUP INSTRUCTIONS

## Step 1: Get Your Free Groq API Key

1. Go to https://console.groq.com
2. Sign up or log in with your Google/GitHub account
3. Navigate to **API Keys** section
4. Click **Create API Key**
5. Copy your API key (it looks like: `gsk_...`)

## Step 2: Add Key to Your .env File

Open your `.env` file in the Zovetica project root and add:

```
GROQ_API_KEY=your_api_key_here
```

Replace `your_api_key_here` with your actual Groq API key.

## Step 3: Restart Your App

After adding the API key:
1. Hot restart the Flutter app (press 'r' in terminal)
2. OR stop and run `flutter run` again

## Testing

Tap "Ask AI" on the home screen and send a test message like:
- "What should I feed my dog?"
- "Signs of illness in cats"

You should get an instant AI response!

## Troubleshooting

**Error: "Groq API key not found"**
- Make sure you added `GROQ_API_KEY=...` to your `.env` file
- Restart the app completely

**Error: "Rate limit exceeded"**
- Free tier: 30 requests per minute
- Wait a minute and try again

**Error: "Failed to get AI response"**
- Check your internet connection
- Verify API key is correct

## Free Tier Limits

- **Requests:** 30 per minute
- **Daily:** 14,400 requests
- **Tokens:** 6,000 per minute
- **Cost:** FREE

Perfect for a pet healthcare app!
