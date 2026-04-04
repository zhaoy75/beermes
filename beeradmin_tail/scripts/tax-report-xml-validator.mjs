import { createServer } from 'node:http'
import { mkdtemp, rm, writeFile } from 'node:fs/promises'
import { spawn } from 'node:child_process'
import { tmpdir } from 'node:os'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const repoRoot = resolve(__dirname, '..', '..')
const host = process.env.TAX_REPORT_XML_VALIDATOR_HOST || '127.0.0.1'
const port = Number(process.env.TAX_REPORT_XML_VALIDATOR_PORT || 54331)

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const schemaMap = {
  RLI0010_232: resolve(repoRoot, 'etax/19XMLスキーマ/shuzei/RLI0010-232.xsd'),
}

const server = createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    writeJson(res, 200, 'ok', { raw: true })
    return
  }

  if (req.method !== 'POST' || req.url !== '/validate-tax-report-xml') {
    writeJson(res, 404, { error: 'Not found' })
    return
  }

  try {
    const body = await readJson(req)
    const reportName = typeof body.reportName === 'string' ? body.reportName : ''
    const xml = typeof body.xml === 'string' ? body.xml : ''
    const schemaPath = schemaMap[reportName]

    if (!reportName || !xml) {
      writeJson(res, 400, { error: 'reportName and xml are required' })
      return
    }
    if (!schemaPath) {
      writeJson(res, 400, { error: `Unsupported reportName: ${reportName}` })
      return
    }

    const result = await validateXml({ xml, schemaPath })
    if (!result.valid) {
      writeJson(res, 422, {
        code: 'XSD_VALIDATION_FAILED',
        reportName,
        valid: false,
        messages: result.messages,
      })
      return
    }

    writeJson(res, 200, {
      reportName,
      valid: true,
      messages: [],
    })
  } catch (error) {
    writeJson(res, 500, {
      code: 'XSD_VALIDATION_ERROR',
      messages: [{
        level: 'error',
        source: 'xsd',
        code: 'XSD_VALIDATION_ERROR',
        message: error instanceof Error ? error.message : String(error),
      }],
    })
  }
})

server.listen(port, host, () => {
  console.log(`tax-report-xml-validator listening on http://${host}:${port}/validate-tax-report-xml`)
})

async function validateXml({ xml, schemaPath }) {
  const tempDir = await mkdtemp(resolve(tmpdir(), 'tax-report-xml-'))
  const xmlPath = resolve(tempDir, 'payload.xml')

  try {
    await writeFile(xmlPath, xml, 'utf8')
    const { code, stdout, stderr } = await runCommand('xmllint', ['--noout', '--schema', schemaPath, xmlPath])
    if (code === 0) {
      return { valid: true, messages: [] }
    }
    return {
      valid: false,
      messages: parseXmllintMessages(stderr || stdout),
    }
  } finally {
    await rm(tempDir, { recursive: true, force: true })
  }
}

function runCommand(command, args) {
  return new Promise((resolvePromise, rejectPromise) => {
    const child = spawn(command, args, {
      cwd: repoRoot,
      stdio: ['ignore', 'pipe', 'pipe'],
    })

    let stdout = ''
    let stderr = ''

    child.stdout.on('data', (chunk) => {
      stdout += String(chunk)
    })
    child.stderr.on('data', (chunk) => {
      stderr += String(chunk)
    })
    child.on('error', rejectPromise)
    child.on('close', (code) => {
      resolvePromise({
        code: typeof code === 'number' ? code : 1,
        stdout: stdout.trim(),
        stderr: stderr.trim(),
      })
    })
  })
}

function parseXmllintMessages(text) {
  const lines = String(text)
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)

  if (lines.length === 0) {
    return [{
      level: 'error',
      source: 'xsd',
      code: 'XML_SCHEMA_ERROR',
      message: 'XSD validation failed.',
    }]
  }

  return lines.map((message) => ({
    level: 'error',
    source: 'xsd',
    code: 'XML_SCHEMA_ERROR',
    message,
  }))
}

function readJson(req) {
  return new Promise((resolvePromise, rejectPromise) => {
    let body = ''
    req.setEncoding('utf8')
    req.on('data', (chunk) => {
      body += chunk
    })
    req.on('end', () => {
      try {
        resolvePromise(body ? JSON.parse(body) : {})
      } catch (error) {
        rejectPromise(error)
      }
    })
    req.on('error', rejectPromise)
  })
}

function writeJson(res, status, payload, options = {}) {
  const raw = options.raw === true
  const body = raw ? String(payload) : JSON.stringify(payload)
  res.writeHead(status, {
    ...corsHeaders,
    'Content-Type': raw ? 'text/plain; charset=utf-8' : 'application/json',
  })
  res.end(body)
}
