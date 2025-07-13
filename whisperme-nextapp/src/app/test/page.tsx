"use client"

import { useState, useRef } from "react"
import { Mic, Upload, Play, Square, Loader2, Copy, Check } from "lucide-react"

interface TranscriptionResponse {
  text: string
  usage_remaining: number
  is_premium: boolean
}

interface TranscriptionError {
  detail: string
}

interface RequestDetails {
  url: string
  method: string
  headers: Record<string, string>
  formData: {
    device_id: string
    language: string
    model: string
    prompt: string
    audio_file: {
      name: string
      size: string
      type: string
    }
  }
  timestamp: string
}

// Based on official OpenAI Whisper API documentation
// Supported language codes: https://platform.openai.com/docs/guides/speech-to-text
const SUPPORTED_LANGUAGES = [
  { code: "auto", name: "Auto-detect" },
  { code: "af", name: "Afrikaans" },
  { code: "ar", name: "Arabic" },
  { code: "az", name: "Azerbaijani" },
  { code: "be", name: "Belarusian" },
  { code: "bg", name: "Bulgarian" },
  { code: "bs", name: "Bosnian" },
  { code: "ca", name: "Catalan" },
  { code: "cs", name: "Czech" },
  { code: "cy", name: "Welsh" },
  { code: "da", name: "Danish" },
  { code: "de", name: "German" },
  { code: "el", name: "Greek" },
  { code: "en", name: "English" },
  { code: "es", name: "Spanish" },
  { code: "et", name: "Estonian" },
  { code: "fa", name: "Persian" },
  { code: "fi", name: "Finnish" },
  { code: "fr", name: "French" },
  { code: "gl", name: "Galician" },
  { code: "he", name: "Hebrew" },
  { code: "hi", name: "Hindi" },
  { code: "hr", name: "Croatian" },
  { code: "hu", name: "Hungarian" },
  { code: "hy", name: "Armenian" },
  { code: "id", name: "Indonesian" },
  { code: "is", name: "Icelandic" },
  { code: "it", name: "Italian" },
  { code: "ja", name: "Japanese" },
  { code: "kk", name: "Kazakh" },
  { code: "kn", name: "Kannada" },
  { code: "ko", name: "Korean" },
  { code: "lt", name: "Lithuanian" },
  { code: "lv", name: "Latvian" },
  { code: "mi", name: "Māori" },
  { code: "mk", name: "Macedonian" },
  { code: "mr", name: "Marathi" },
  { code: "ms", name: "Malay" },
  { code: "ne", name: "Nepali" },
  { code: "nl", name: "Dutch" },
  { code: "no", name: "Norwegian" },
  { code: "pl", name: "Polish" },
  { code: "pt", name: "Portuguese" },
  { code: "ro", name: "Romanian" },
  { code: "ru", name: "Russian" },
  { code: "sk", name: "Slovak" },
  { code: "sl", name: "Slovenian" },
  { code: "sr", name: "Serbian" },
  { code: "sv", name: "Swedish" },
  { code: "sw", name: "Swahili" },
  { code: "ta", name: "Tamil" },
  { code: "th", name: "Thai" },
  { code: "tl", name: "Tagalog" },
  { code: "tr", name: "Turkish" },
  { code: "uk", name: "Ukrainian" },
  { code: "ur", name: "Urdu" },
  { code: "vi", name: "Vietnamese" },
  { code: "zh", name: "Chinese" }
]

const AVAILABLE_MODELS = [
  { id: "gpt-4o-transcribe", name: "GPT-4O Transcribe (High Quality)" },
  { id: "gpt-4o-mini-transcribe", name: "GPT-4O Mini Transcribe (Fast)" }
]

export default function TestPage() {
  const [audioFile, setAudioFile] = useState<File | null>(null)
  const [deviceId, setDeviceId] = useState("test_device_" + Math.random().toString(36).substr(2, 9))
  const [language, setLanguage] = useState("en")
  const [model, setModel] = useState("gpt-4o-transcribe")
  const [prompt, setPrompt] = useState("")
  const [transcriptionResult, setTranscriptionResult] = useState<TranscriptionResponse | null>(null)
  const [isTranscribing, setIsTranscribing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isRecording, setIsRecording] = useState(false)
  const [mediaRecorder, setMediaRecorder] = useState<MediaRecorder | null>(null)
  const [copied, setCopied] = useState(false)
  const [requestDetails, setRequestDetails] = useState<RequestDetails | null>(null)
  
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      // Check if it's an audio file
      if (!file.type.startsWith('audio/')) {
        setError("Please select an audio file")
        return
      }
      setAudioFile(file)
      setError(null)
    }
  }

  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ 
        audio: {
          sampleRate: 44100,
          channelCount: 1,
          echoCancellation: true,
          noiseSuppression: true
        }
      })
      
      // Try to use a format that OpenAI supports better
      const options = {
        mimeType: 'audio/webm;codecs=opus'
      }
      
      // Fallback to default if the preferred format isn't supported
      if (!MediaRecorder.isTypeSupported(options.mimeType)) {
        delete (options as { mimeType?: string }).mimeType
      }
      
      const recorder = new MediaRecorder(stream, options)
      const chunks: Blob[] = []

      recorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          chunks.push(event.data)
        }
      }

      recorder.onstop = () => {
        // Create blob with the correct MIME type
        const mimeType = recorder.mimeType || 'audio/webm'
        const blob = new Blob(chunks, { type: mimeType })
        
        // Use appropriate extension based on format
        const extension = mimeType.includes('webm') ? '.webm' : 
                         mimeType.includes('mp4') ? '.mp4' : '.wav'
        
        const file = new File([blob], `recorded_audio${extension}`, { type: mimeType })
        setAudioFile(file)
        
        // Stop all tracks to release microphone
        stream.getTracks().forEach(track => track.stop())
      }

      setMediaRecorder(recorder)
      setIsRecording(true)
      recorder.start()
    } catch (err) {
      setError("Could not access microphone: " + (err as Error).message)
    }
  }

  const stopRecording = () => {
    if (mediaRecorder && isRecording) {
      mediaRecorder.stop()
      setIsRecording(false)
      setMediaRecorder(null)
    }
  }

  const handleTranscribe = async () => {
    if (!audioFile) {
      setError("Please select or record an audio file first")
      return
    }

    setIsTranscribing(true)
    setError(null)
    setTranscriptionResult(null)
    setRequestDetails(null)

    try {
      const formData = new FormData()
      formData.append('audio_file', audioFile)
      formData.append('device_id', deviceId)
      
      // Only send language if it's not auto-detect
      if (language !== 'auto') {
        formData.append('language', language)
      }
      
      formData.append('model', model)
      if (prompt.trim()) {
        formData.append('prompt', prompt.trim())
      }

      // Log request details
      const requestInfo: RequestDetails = {
        url: `${process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000'}/transcribe`,
        method: 'POST',
        headers: {
          'Content-Type': 'multipart/form-data'
        },
        formData: {
          device_id: deviceId,
          language: language !== 'auto' ? language : 'auto (not sent to API)',
          model: model,
          prompt: prompt.trim() || '(none)',
          audio_file: {
            name: audioFile.name,
            size: `${(audioFile.size / 1024).toFixed(2)} KB`,
            type: audioFile.type
          }
        },
        timestamp: new Date().toISOString()
      }
      setRequestDetails(requestInfo)

      // Use environment variable for backend URL or default to localhost
      const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000'
      const response = await fetch(`${backendUrl}/transcribe`, {
        method: 'POST',
        body: formData,
      })

      if (!response.ok) {
        const errorData: TranscriptionError = await response.json()
        throw new Error(errorData.detail || `HTTP error! status: ${response.status}`)
      }

      const result: TranscriptionResponse = await response.json()
      setTranscriptionResult(result)
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setIsTranscribing(false)
    }
  }

  const copyToClipboard = async () => {
    if (transcriptionResult?.text) {
      await navigator.clipboard.writeText(transcriptionResult.text)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    }
  }

  const clearAll = () => {
    setAudioFile(null)
    setTranscriptionResult(null)
    setError(null)
    setRequestDetails(null)
    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-50 to-white py-8">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            WhisperMe API Test Interface
          </h1>
          <p className="text-gray-600">
            Test the transcription API directly with file upload, recording, and custom parameters
          </p>
        </div>

        <div className="bg-white rounded-lg shadow-lg p-6 space-y-6">
          {/* Device ID */}
          <div>
            <label htmlFor="deviceId" className="block text-sm font-medium text-gray-700 mb-2">
              Device ID
            </label>
            <input
              type="text"
              id="deviceId"
              value={deviceId}
              onChange={(e) => setDeviceId(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="Enter device ID"
            />
          </div>

          {/* Language Selection */}
          <div>
            <label htmlFor="language" className="block text-sm font-medium text-gray-700 mb-2">
              Language
            </label>
            <select
              id="language"
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              {SUPPORTED_LANGUAGES.map((lang) => (
                <option key={lang.code} value={lang.code}>
                  {lang.name}
                </option>
              ))}
            </select>
          </div>

          {/* Model Selection */}
          <div>
            <label htmlFor="model" className="block text-sm font-medium text-gray-700 mb-2">
              Model
            </label>
            <select
              id="model"
              value={model}
              onChange={(e) => setModel(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              {AVAILABLE_MODELS.map((modelOption) => (
                <option key={modelOption.id} value={modelOption.id}>
                  {modelOption.name}
                </option>
              ))}
            </select>
          </div>

          {/* Custom Prompt */}
          <div>
            <label htmlFor="prompt" className="block text-sm font-medium text-gray-700 mb-2">
              Custom Prompt (Optional)
            </label>
            <textarea
              id="prompt"
              value={prompt}
              onChange={(e) => setPrompt(e.target.value)}
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="Enter any custom instructions for transcription (e.g., &lsquo;Format as a structured document&rsquo;, &lsquo;Include speaker labels&rsquo;, etc.)"
            />
          </div>

          {/* Audio Input Section */}
          <div className="space-y-4">
            <h3 className="text-lg font-medium text-gray-900">Audio Input</h3>
            
            {/* File Upload */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Upload Audio File
              </label>
              <div className="flex items-center space-x-4">
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <Upload className="w-4 h-4 mr-2" />
                  Choose File
                </button>
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="audio/*"
                  onChange={handleFileSelect}
                  className="hidden"
                />
                {audioFile && (
                  <span className="text-sm text-gray-600">
                    {audioFile.name} ({(audioFile.size / 1024 / 1024).toFixed(2)} MB)
                  </span>
                )}
              </div>
            </div>

            {/* Recording */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Or Record Audio
              </label>
              <button
                onClick={isRecording ? stopRecording : startRecording}
                className={`inline-flex items-center px-4 py-2 rounded-md shadow-sm text-sm font-medium focus:outline-none focus:ring-2 focus:ring-indigo-500 ${
                  isRecording
                    ? 'bg-red-600 text-white hover:bg-red-700'
                    : 'bg-indigo-600 text-white hover:bg-indigo-700'
                }`}
              >
                {isRecording ? (
                  <>
                    <Square className="w-4 h-4 mr-2" />
                    Stop Recording
                  </>
                ) : (
                  <>
                    <Mic className="w-4 h-4 mr-2" />
                    Start Recording
                  </>
                )}
              </button>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex space-x-4">
            <button
              onClick={handleTranscribe}
              disabled={!audioFile || isTranscribing}
              className="flex-1 inline-flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              {isTranscribing ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  Transcribing...
                </>
              ) : (
                <>
                  <Play className="w-4 h-4 mr-2" />
                  Transcribe Audio
                </>
              )}
            </button>
            
            <button
              onClick={clearAll}
              className="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              Clear All
            </button>
          </div>

          {/* Request Details Display */}
          {requestDetails && (
            <div className="bg-blue-50 border border-blue-200 rounded-md p-4">
              <h3 className="text-lg font-medium text-blue-900 mb-3">API Request Details</h3>
              <div className="space-y-3">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                  <div>
                    <strong className="text-blue-800">URL:</strong>
                    <p className="text-blue-700 font-mono break-all">{requestDetails.url}</p>
                  </div>
                  <div>
                    <strong className="text-blue-800">Method:</strong>
                    <p className="text-blue-700">{requestDetails.method}</p>
                  </div>
                  <div>
                    <strong className="text-blue-800">Device ID:</strong>
                    <p className="text-blue-700 font-mono">{requestDetails.formData.device_id}</p>
                  </div>
                  <div>
                    <strong className="text-blue-800">Language:</strong>
                    <p className="text-blue-700">{requestDetails.formData.language}</p>
                  </div>
                  <div>
                    <strong className="text-blue-800">Model:</strong>
                    <p className="text-blue-700">{requestDetails.formData.model}</p>
                  </div>
                  <div>
                    <strong className="text-blue-800">Prompt:</strong>
                    <p className="text-blue-700">{requestDetails.formData.prompt}</p>
                  </div>
                </div>
                <div className="border-t border-blue-200 pt-3">
                  <strong className="text-blue-800">Audio File:</strong>
                  <div className="text-blue-700 text-sm mt-1">
                    <p><strong>Name:</strong> {requestDetails.formData.audio_file.name}</p>
                    <p><strong>Size:</strong> {requestDetails.formData.audio_file.size}</p>
                    <p><strong>Type:</strong> {requestDetails.formData.audio_file.type}</p>
                  </div>
                </div>
                <div className="text-xs text-blue-600">
                  <strong>Timestamp:</strong> {new Date(requestDetails.timestamp).toLocaleString()}
                </div>
              </div>
            </div>
          )}

          {/* Error Display */}
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-md p-4">
              <div className="flex">
                <div className="text-sm text-red-700">
                  <strong>Error:</strong> {error}
                </div>
              </div>
            </div>
          )}

          {/* Results Display */}
          {transcriptionResult && (
            <div className="bg-green-50 border border-green-200 rounded-md p-4 space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-medium text-green-900">Transcription Result</h3>
                <button
                  onClick={copyToClipboard}
                  className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-green-700 bg-green-100 hover:bg-green-200 focus:outline-none focus:ring-2 focus:ring-green-500"
                >
                  {copied ? (
                    <>
                      <Check className="w-4 h-4 mr-1" />
                      Copied!
                    </>
                  ) : (
                    <>
                      <Copy className="w-4 h-4 mr-1" />
                      Copy
                    </>
                  )}
                </button>
              </div>
              
              <div className="bg-white border border-green-200 rounded-md p-4">
                <p className="text-gray-900 whitespace-pre-wrap">{transcriptionResult.text}</p>
              </div>
              
              <div className="text-sm text-green-700 space-y-1">
                <p><strong>Usage Remaining:</strong> {transcriptionResult.usage_remaining}</p>
                <p><strong>Premium User:</strong> {transcriptionResult.is_premium ? 'Yes' : 'No'}</p>
              </div>
            </div>
          )}

          {/* API Information */}
          <div className="bg-gray-50 border border-gray-200 rounded-md p-4">
            <h3 className="text-lg font-medium text-gray-900 mb-2">API Information</h3>
            <div className="text-sm text-gray-600 space-y-1">
              <p><strong>Backend URL:</strong> {process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000'}</p>
              <p><strong>Endpoint:</strong> POST /transcribe</p>
              <p><strong>Supported Formats:</strong> MP3, MP4, MPEG, MPGA, M4A, WAV, WEBM</p>
              <p><strong>Max File Size:</strong> 25MB (OpenAI limit)</p>
              <p><strong>Recording Format:</strong> Browser will use WebM with Opus codec when available</p>
            </div>
          </div>

          {/* Troubleshooting */}
          <div className="bg-yellow-50 border border-yellow-200 rounded-md p-4">
            <h3 className="text-lg font-medium text-yellow-800 mb-2">Troubleshooting & Notes</h3>
            <div className="text-sm text-yellow-700 space-y-2">
              <p><strong>Language Parameter:</strong> When &ldquo;Auto-detect&rdquo; is selected, no language parameter is sent to the API, letting OpenAI auto-detect. Specific languages send the language code.</p>
              <p><strong>Format errors:</strong> If you get &ldquo;unsupported format&rdquo; errors, try uploading a different audio file format (MP3 or M4A work well).</p>
              <p><strong>Recording format:</strong> Browser recording now uses WebM with Opus codec, which works well with OpenAI&rsquo;s API.</p>
              <p><strong>Recording issues:</strong> If recording doesn&rsquo;t work, check browser permissions for microphone access.</p>
              <p><strong>Backend connection:</strong> Ensure the Python backend is running on port 8000.</p>
              <p><strong>CORS errors:</strong> Make sure NEXT_PUBLIC_BACKEND_URL is set correctly in your .env.local file.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
} 