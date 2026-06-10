import { z } from 'zod'

export const rawKboGameDateResponseSchema = z.object({
  BEFORE_G_DT: z.string(),
  NOW_G_DT: z.string(),
  NOW_G_DT_TEXT: z.string(),
  AFTER_G_DT: z.string(),
  code: z.string(),
  msg: z.string()
}).passthrough()

export type RawKboGameDateResponse = z.infer<typeof rawKboGameDateResponseSchema>
