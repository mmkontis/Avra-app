# WhisperMe Next.js Web Application

A modern web application for user authentication and account management for the WhisperMe transcription service.

## Features

- **User Authentication**: Email/password registration and login
- **User Dashboard**: View usage statistics and account information
- **Premium Upgrades**: Upgrade to premium for unlimited transcriptions
- **API Test Interface**: Test transcription API directly with file upload, recording, and custom parameters
- **Responsive Design**: Built with Tailwind CSS for modern UI
- **Secure**: JWT-based authentication with bcrypt password hashing
- **Integration**: Seamlessly integrates with the Python backend

## Tech Stack

- **Framework**: Next.js 14 with App Router
- **Authentication**: NextAuth.js with custom credentials provider
- **Styling**: Tailwind CSS
- **Forms**: React Hook Form with Zod validation
- **API Client**: Axios
- **TypeScript**: Full type safety

## Prerequisites

- Node.js 18+ and npm
- Python backend running on `http://localhost:8000`

## Environment Setup

Create a `.env.local` file in the root directory:

```env
# NextAuth Configuration
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-nextauth-secret-key-here-change-in-production

# Backend API Configuration
NEXT_PUBLIC_BACKEND_URL=http://localhost:8000
```

**Important**: 
- Generate a secure `NEXTAUTH_SECRET` for production
- The `NEXT_PUBLIC_` prefix makes the backend URL available to the client

## Installation

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Set up environment variables**:
   Create the `.env.local` file as described above

3. **Start the development server**:
   ```bash
   npm run dev
   ```

4. **Open your browser**:
   Navigate to `http://localhost:3000`

## Project Structure

```
src/
├── app/                    # Next.js App Router pages
│   ├── auth/
│   │   ├── login/         # Login page
│   │   └── register/      # Registration page
│   ├── dashboard/         # User dashboard
│   ├── api/
│   │   └── auth/          # NextAuth API routes
│   ├── layout.tsx         # Root layout with providers
│   └── page.tsx           # Home page
├── components/
│   └── providers.tsx      # Session provider wrapper
└── lib/
    └── auth.ts            # NextAuth configuration
```

## API Integration

The web app integrates with the Python backend for:

- **User Registration**: `POST /auth/register`
- **User Login**: `POST /auth/login`
- **User Statistics**: `GET /user/stats` (requires JWT token)
- **Premium Upgrade**: `POST /user/upgrade` (requires JWT token)

## Authentication Flow

1. **Registration**: Users create account with name, email, and password
2. **Login**: Users sign in with email/password, receive JWT token
3. **Dashboard**: Authenticated users can view stats and upgrade account
4. **Token Management**: JWT tokens stored in NextAuth session

## Usage Statistics

- **Free Tier**: 10 transcriptions per day
- **Premium Tier**: Unlimited transcriptions
- **Daily Reset**: Usage counters reset at midnight

## Development

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint

### Code Quality

- TypeScript for type safety
- ESLint for code linting
- Prettier for code formatting (recommended)

## Deployment

1. **Build the application**:
   ```bash
   npm run build
   ```

2. **Set production environment variables**:
   - Update `NEXTAUTH_URL` to your domain
   - Generate secure `NEXTAUTH_SECRET`
   - Update `NEXT_PUBLIC_BACKEND_URL` to production backend

3. **Deploy to your platform**:
   - Vercel (recommended for Next.js)
   - Netlify
   - AWS
   - Docker

## Integration with macOS App

The web application complements the native macOS app:

- **Web App**: User registration, account management, billing
- **macOS App**: Voice transcription with device-based authentication
- **Backend**: Unified API serving both clients

## Troubleshooting

### Common Issues

1. **"Module not found" errors**: Run `npm install` to ensure all dependencies are installed

2. **Authentication errors**: Verify `.env.local` file exists and has correct values

3. **Backend connection errors**: Ensure Python backend is running on port 8000

4. **CORS errors**: Backend is configured to allow requests from `http://localhost:3000`

### Backend Health Check

Verify backend is running:
```bash
curl http://localhost:8000/
```

Should return: `{"message": "WhisperMe Backend API", "version": "1.0.0"}`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is part of the WhisperMe transcription service.

## Support

For issues and questions:
- Check the troubleshooting section
- Review backend logs
- Verify environment configuration
