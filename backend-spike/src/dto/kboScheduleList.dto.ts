import { z } from 'zod'

export const rawKboScheduleCellSchema = z.object({
  Text: z.string().optional().nullable(),
  Class: z.string().optional().nullable()
}).passthrough()

export const rawKboScheduleRowSchema = z.object({
  row: z.array(rawKboScheduleCellSchema)
}).passthrough()

export const rawKboScheduleListResponseSchema = z.object({
  rows: z.array(rawKboScheduleRowSchema)
}).passthrough()

export type RawKboScheduleListResponse = z.infer<typeof rawKboScheduleListResponseSchema>
