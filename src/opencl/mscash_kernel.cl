/*
 * This software is Copyright (c) 2013 Sayantan Datta <std2048 at gmail dot com>
 * and it is hereby released to the general public under the following terms:
 * Redistribution and use in source and binary forms, with or without modification, are permitted.
 * This is format is based on mscash-cuda by Lukas Odzioba
 * <lukas dot odzioba at gmail dot com>
 */

#include "opencl_mscash.h"
#include "opencl_shared_mask.h"

#define BITMAP_HASH_0 	    (BITMAP_SIZE_0 - 1)
#define BITMAP_HASH_1	    (BITMAP_SIZE_1 - 1)
#define BITMAP_HASH_3	    (BITMAP_SIZE_3 - 1)

#define PUTCHAR(buf, index, val) (buf)[(index)>>1] = ((buf)[(index)>>1] & ~(0xffU << (((index) & 1) << 4))) + ((val) << (((index) & 1) << 4))

inline void md4_crypt(__private uint *output, __private uint *nt_buffer)
{
	unsigned int a = INIT_A;
	unsigned int b = INIT_B;
	unsigned int c = INIT_C;
	unsigned int d = INIT_D;

	/* Round 1 */
	a += (d ^ (b & (c ^ d))) + nt_buffer[0];
	a = (a << 3) | (a >> 29);
	d += (c ^ (a & (b ^ c))) + nt_buffer[1];
	d = (d << 7) | (d >> 25);
	c += (b ^ (d & (a ^ b))) + nt_buffer[2];
	c = (c << 11) | (c >> 21);
	b += (a ^ (c & (d ^ a))) + nt_buffer[3];
	b = (b << 19) | (b >> 13);

	a += (d ^ (b & (c ^ d))) + nt_buffer[4];
	a = (a << 3) | (a >> 29);
	d += (c ^ (a & (b ^ c))) + nt_buffer[5];
	d = (d << 7) | (d >> 25);
	c += (b ^ (d & (a ^ b))) + nt_buffer[6];
	c = (c << 11) | (c >> 21);
	b += (a ^ (c & (d ^ a))) + nt_buffer[7];
	b = (b << 19) | (b >> 13);

	a += (d ^ (b & (c ^ d))) + nt_buffer[8];
	a = (a << 3) | (a >> 29);
	d += (c ^ (a & (b ^ c))) + nt_buffer[9];
	d = (d << 7) | (d >> 25);
	c += (b ^ (d & (a ^ b))) + nt_buffer[10];
	c = (c << 11) | (c >> 21);
	b += (a ^ (c & (d ^ a))) + nt_buffer[11];
	b = (b << 19) | (b >> 13);

	a += (d ^ (b & (c ^ d))) + nt_buffer[12];
	a = (a << 3) | (a >> 29);
	d += (c ^ (a & (b ^ c))) + nt_buffer[13];
	d = (d << 7) | (d >> 25);
	c += (b ^ (d & (a ^ b))) + nt_buffer[14];
	c = (c << 11) | (c >> 21);
	b += (a ^ (c & (d ^ a))) + nt_buffer[15];
	b = (b << 19) | (b >> 13);

	/* Round 2 */
	a += ((b & (c | d)) | (c & d)) + nt_buffer[0] + SQRT_2;
	a = (a << 3) | (a >> 29);
	d += ((a & (b | c)) | (b & c)) + nt_buffer[4] + SQRT_2;
	d = (d << 5) | (d >> 27);
	c += ((d & (a | b)) | (a & b)) + nt_buffer[8] + SQRT_2;
	c = (c << 9) | (c >> 23);
	b += ((c & (d | a)) | (d & a)) + nt_buffer[12] + SQRT_2;
	b = (b << 13) | (b >> 19);

	a += ((b & (c | d)) | (c & d)) + nt_buffer[1] + SQRT_2;
	a = (a << 3) | (a >> 29);
	d += ((a & (b | c)) | (b & c)) + nt_buffer[5] + SQRT_2;
	d = (d << 5) | (d >> 27);
	c += ((d & (a | b)) | (a & b)) + nt_buffer[9] + SQRT_2;
	c = (c << 9) | (c >> 23);
	b += ((c & (d | a)) | (d & a)) + nt_buffer[13] + SQRT_2;
	b = (b << 13) | (b >> 19);

	a += ((b & (c | d)) | (c & d)) + nt_buffer[2] + SQRT_2;
	a = (a << 3) | (a >> 29);
	d += ((a & (b | c)) | (b & c)) + nt_buffer[6] + SQRT_2;
	d = (d << 5) | (d >> 27);
	c += ((d & (a | b)) | (a & b)) + nt_buffer[10] + SQRT_2;
	c = (c << 9) | (c >> 23);
	b += ((c & (d | a)) | (d & a)) + nt_buffer[14] + SQRT_2;
	b = (b << 13) | (b >> 19);

	a += ((b & (c | d)) | (c & d)) + nt_buffer[3] + SQRT_2;
	a = (a << 3) | (a >> 29);
	d += ((a & (b | c)) | (b & c)) + nt_buffer[7] + SQRT_2;
	d = (d << 5) | (d >> 27);
	c += ((d & (a | b)) | (a & b)) + nt_buffer[11] + SQRT_2;
	c = (c << 9) | (c >> 23);
	b += ((c & (d | a)) | (d & a)) + nt_buffer[15] + SQRT_2;
	b = (b << 13) | (b >> 19);

	/* Round 3 */
	a += (d ^ c ^ b) + nt_buffer[0] + SQRT_3;
	a = (a << 3) | (a >> 29);
	d += (c ^ b ^ a) + nt_buffer[8] + SQRT_3;
	d = (d << 9) | (d >> 23);
	c += (b ^ a ^ d) + nt_buffer[4] + SQRT_3;
	c = (c << 11) | (c >> 21);
	b += (a ^ d ^ c) + nt_buffer[12] + SQRT_3;
	b = (b << 15) | (b >> 17);

	a += (d ^ c ^ b) + nt_buffer[2] + SQRT_3;
	a = (a << 3) | (a >> 29);
	d += (c ^ b ^ a) + nt_buffer[10] + SQRT_3;
	d = (d << 9) | (d >> 23);
	c += (b ^ a ^ d) + nt_buffer[6] + SQRT_3;
	c = (c << 11) | (c >> 21);
	b += (a ^ d ^ c) + nt_buffer[14] + SQRT_3;
	b = (b << 15) | (b >> 17);

	a += (d ^ c ^ b) + nt_buffer[1] + SQRT_3;
	a = (a << 3) | (a >> 29);
	d += (c ^ b ^ a) + nt_buffer[9] + SQRT_3;
	d = (d << 9) | (d >> 23);
	c += (b ^ a ^ d) + nt_buffer[5] + SQRT_3;
	c = (c << 11) | (c >> 21);
	b += (a ^ d ^ c) + nt_buffer[13] + SQRT_3;
	b = (b << 15) | (b >> 17);

	a += (d ^ c ^ b) + nt_buffer[3] + SQRT_3;
	a = (a << 3) | (a >> 29);
	d += (c ^ b ^ a) + nt_buffer[11] + SQRT_3;
	d = (d << 9) | (d >> 23);
	c += (b ^ a ^ d) + nt_buffer[7] + SQRT_3;
	c = (c << 11) | (c >> 21);
	b += (a ^ d ^ c) + nt_buffer[15] + SQRT_3;
	b = (b << 15) | (b >> 17);

	output[0] = a + INIT_A;
	output[1] = b + INIT_B;
	output[2] = c + INIT_C;
	output[3] = d + INIT_D;
}

inline void prepare_key(__global uint * key, int length, uint * nt_buffer)
{
	uint i = 0, nt_index, keychars;
	nt_index = 0;
	for (i = 0; i < (length + 3)/ 4; i++) {
		keychars = key[i];
		nt_buffer[nt_index++] = (keychars & 0xFF) | (((keychars >> 8) & 0xFF) << 16);
		nt_buffer[nt_index++] = ((keychars >> 16) & 0xFF) | ((keychars >> 24) << 16);
	}
	nt_index = length >> 1;
	nt_buffer[nt_index] = (nt_buffer[nt_index] & 0xFF) | (0x80 << ((length & 1) << 4));
	nt_buffer[nt_index + 1] = 0;
	nt_buffer[14] = length << 4;
}

inline void cmp(
	  __global uint *loaded_hashes,
	  __local uint *bitmap0,
	  __local uint *bitmap1,
	  __local uint *bitmap2,
	  __local uint *bitmap3,
	  __global uint *gbitmap0,
	  __global uint *hashtable0,
	  __global uint *loaded_hash_next,
	  __private uint *hash,
	  __global uint *outKeyIdx,
	  uint gid,
	  uint num_loaded_hashes,
	  uint keyIdx) {

	uint loaded_hash, i, tmp;

	loaded_hash = hash[0] & BITMAP_HASH_1;
	tmp = (bitmap0[loaded_hash >> 5] >> (loaded_hash & 31)) & 1U ;
	loaded_hash = hash[1] & BITMAP_HASH_1;
	tmp &= (bitmap1[loaded_hash >> 5] >> (loaded_hash & 31)) & 1U;
	loaded_hash = hash[2] & BITMAP_HASH_1;
	tmp &= (bitmap2[loaded_hash >> 5] >> (loaded_hash & 31)) & 1U ;
	loaded_hash = hash[3] & BITMAP_HASH_1;
	tmp &= (bitmap3[loaded_hash >> 5] >> (loaded_hash & 31)) & 1U;
	if(tmp) {
		loaded_hash = hash[0] & BITMAP_HASH_3;
		tmp &= (gbitmap0[loaded_hash >> 5] >> (loaded_hash & 31)) & 1U;
		if (tmp) {
		i = hashtable0[hash[2] & (HASH_TABLE_SIZE_0 - 1)];
			if (i ^ 0xFFFFFFFF) {
				do {
					if (hash[0] == loaded_hashes[i + 1])
					if ((hash[1] == loaded_hashes[i + num_loaded_hashes + 1]) &&
					    (hash[2] == loaded_hashes[i + 2 * num_loaded_hashes + 1]) &&
					    (hash[3] == loaded_hashes[i + 3 * num_loaded_hashes + 1])) {
						outKeyIdx[i] = gid | 0x80000000;
						outKeyIdx[i + num_loaded_hashes] = keyIdx;
					}
					i = loaded_hash_next[i];
				} while(i ^ 0xFFFFFFFF);
			}
		}
	}

}

__kernel void mscash_self_test(__global uint *keys, __global ulong *keyIdx, __global uint *salt, __global uint *outBuffer) {

	int gid = get_global_id(0), i;
	int lid = get_local_id(0);
	int numkeys = get_global_size(0);
	uint nt_buffer[16] = { 0 };
	uint output[4] = { 0 };
	ulong base = keyIdx[gid];
	uint passwordlength = base & 63;

	keys += base >> 6;

	__local uint login[12];

	if(!lid)
		for(i = 0; i < 12; i++)
			login[i] = salt[i];
	barrier(CLK_LOCAL_MEM_FENCE);

	prepare_key(keys, passwordlength, nt_buffer);
	md4_crypt(output, nt_buffer);
	nt_buffer[0] = output[0];
	nt_buffer[1] = output[1];
	nt_buffer[2] = output[2];
	nt_buffer[3] = output[3];

	for(i = 0; i < 12; i++)
		nt_buffer[i + 4] = login[i];
	md4_crypt(output, nt_buffer);

	outBuffer[gid] = output[0];
	outBuffer[gid + numkeys] = output[1];
	outBuffer[gid + 2 * numkeys] = output[2];
	outBuffer[gid + 3 * numkeys] = output[3];
}

__kernel void mscash_om(__global uint *keys,
		     __global ulong *keyIdx,
		     __global uint *outKeyIdx,
		     __global struct mask_context *msk_ctx,
		     __global uint *salt,
		     __global uint *loaded_hashes,
		     __global struct bitmap_context_mixed *bitmap1,
		     __global struct bitmap_context_global *bitmap2) {

	uint gid = get_global_id(0), i;
	uint lid = get_local_id(0);
	uint nt_buffer[16] = { 0 };
	uint output[4] = { 0 };
	ulong base = keyIdx[gid];
	uint num_loaded_hashes = loaded_hashes[0];
	uint passwordlength = base & 63;

	keys += base >> 6;

	__local uint sbitmap0[BITMAP_SIZE_1 >> 5];
	__local uint sbitmap1[BITMAP_SIZE_1 >> 5];
	__local uint sbitmap2[BITMAP_SIZE_1 >> 5];
	__local uint sbitmap3[BITMAP_SIZE_1 >> 5];
	__local uint login[12];

	for(i = 0; i < ((BITMAP_SIZE_1 >> 5) / LWS); i++)
		sbitmap0[i*LWS + lid] = bitmap1[0].bitmap0[i*LWS + lid];

	for(i = 0; i < ((BITMAP_SIZE_1 >> 5)/ LWS); i++)
		sbitmap1[i*LWS + lid] = bitmap1[0].bitmap1[i*LWS + lid];

	for(i = 0; i < ((BITMAP_SIZE_1 >> 5) / LWS); i++)
		sbitmap2[i*LWS + lid] = bitmap1[0].bitmap2[i*LWS + lid];

	for(i = 0; i < ((BITMAP_SIZE_1 >> 5)/ LWS); i++)
		sbitmap3[i*LWS + lid] = bitmap1[0].bitmap3[i*LWS + lid];

	if(!lid)
		for(i = 0; i < 12; i++)
			login[i] = salt[i];
	barrier(CLK_LOCAL_MEM_FENCE);

	if(gid==1)
		for (i = 0; i < num_loaded_hashes; i++)
			outKeyIdx[i] = outKeyIdx[i + num_loaded_hashes] = 0;
	barrier(CLK_GLOBAL_MEM_FENCE);

	prepare_key(keys, passwordlength, nt_buffer);
	md4_crypt(output, nt_buffer);
	nt_buffer[0] = output[0];
	nt_buffer[1] = output[1];
	nt_buffer[2] = output[2];
	nt_buffer[3] = output[3];

	for(i = 0; i < 12; i++)
		nt_buffer[i + 4] = login[i];
	md4_crypt(output, nt_buffer);

	cmp(loaded_hashes, sbitmap0, sbitmap1, sbitmap2, sbitmap3, &bitmap1[0].gbitmap0[0],
	    &bitmap2[0].hashtable0[0], &bitmap1[0].loaded_next_hash[0],
	    output, outKeyIdx, gid, num_loaded_hashes, 0);
}

__kernel void mscash_mm(__global uint *keys,
		     __global ulong *keyIdx,
		     __global uint *outKeyIdx,
		     __global struct mask_context *msk_ctx,
		     __global uint *salt,
		     __global uint *loaded_hashes,
		     __global struct bitmap_context_mixed *bitmap1,
		     __global struct bitmap_context_global *bitmap2) {

	int gid = get_global_id(0);
	int lid = get_local_id(0);
	uint nt_buffer[16] = { 0 };
	uint restore[16] = { 0 };
	uint output[4] = { 0 };
	ulong base = keyIdx[gid];
	uint passwordlength = base & 63;
	uint num_loaded_hashes = loaded_hashes[0];
	uchar activeRangePos[3], rangeNumChars[3];
	uint i, j, k, ii, ctr;

	keys += base >> 6;

	__local uint login[12];
	__local uchar ranges[3 * MAX_GPU_CHARS];
	__local uint sbitmap0[BITMAP_SIZE_1 >> 5];
	__local uint sbitmap1[BITMAP_SIZE_1 >> 5];
	__local uint sbitmap2[BITMAP_SIZE_1 >> 5];
	__local uint sbitmap3[BITMAP_SIZE_1 >> 5];

	for(i = 0; i < 3; i++) {
		activeRangePos[i] = msk_ctx[0].activeRangePos[i];
	}

	for(i = 0; i < 3; i++)
		rangeNumChars[i] = msk_ctx[0].ranges[activeRangePos[i]].count;

	// Parallel load , works only if LWS is 64
	ranges[lid] = msk_ctx[0].ranges[activeRangePos[0]].chars[lid];
	ranges[lid + MAX_GPU_CHARS] = msk_ctx[0].ranges[activeRangePos[1]].chars[lid];
	ranges[lid + 2 * MAX_GPU_CHARS] = msk_ctx[0].ranges[activeRangePos[2]].chars[lid];

	for(i = 0; i < ((BITMAP_SIZE_1 >> 5) / LWS); i++)
		sbitmap0[i*LWS + lid] = bitmap1[0].bitmap0[i*LWS + lid];

	for(i = 0; i < ((BITMAP_SIZE_1 >> 5)/ LWS); i++)
		sbitmap1[i*LWS + lid] = bitmap1[0].bitmap1[i*LWS + lid];

	for(i = 0; i < ((BITMAP_SIZE_1 >> 5) / LWS); i++)
		sbitmap2[i*LWS + lid] = bitmap1[0].bitmap2[i*LWS + lid];

	for(i = 0; i < ((BITMAP_SIZE_1 >> 5)/ LWS); i++)
		sbitmap3[i*LWS + lid] = bitmap1[0].bitmap3[i*LWS + lid];

	if(!lid)
		for(i = 0; i < 12; i++)
			login[i] = salt[i];

	barrier(CLK_LOCAL_MEM_FENCE);

	if(msk_ctx[0].flg_wrd) {
		ii = outKeyIdx[gid>>2];
		ii = (ii >> ((gid&3) << 3))&0xFF;
		for(i = 0; i < 3; i++)
			activeRangePos[i] += ii;
		barrier(CLK_GLOBAL_MEM_FENCE);
	}

	if(gid==1)
		for (i = 0; i < num_loaded_hashes; i++)
			outKeyIdx[i] = outKeyIdx[i + num_loaded_hashes] = 0;
	barrier(CLK_GLOBAL_MEM_FENCE);

	prepare_key(keys, passwordlength, nt_buffer);

	for (ii = 0; ii < 16; ii++)
		restore[ii] = nt_buffer[ii];

	ctr = i = j = k = 0;
	if (rangeNumChars[2]) PUTCHAR(restore, activeRangePos[2], ranges[2 * MAX_GPU_CHARS]);
	if (rangeNumChars[1]) PUTCHAR(restore, activeRangePos[1], ranges[MAX_GPU_CHARS]);

	do {
		do {
			for (i = 0; i < rangeNumChars[0]; i++) {
				for(ii = 0; ii < 16; ii++)
					nt_buffer[ii] = restore[ii];
				PUTCHAR(nt_buffer, activeRangePos[0], ranges[i]);
				md4_crypt(output, nt_buffer);
				nt_buffer[0] = output[0];
				nt_buffer[1] = output[1];
				nt_buffer[2] = output[2];
				nt_buffer[3] = output[3];
				for(ii = 0; ii < 12; ii++)
					nt_buffer[ii + 4] = login[ii];
				md4_crypt(output, nt_buffer);
				cmp(loaded_hashes, sbitmap0, sbitmap1, sbitmap2, sbitmap3, &bitmap1[0].gbitmap0[0],
				    &bitmap2[0].hashtable0[0], &bitmap1[0].loaded_next_hash[0],
				    output, outKeyIdx, gid, num_loaded_hashes, ctr++);
			}

			j++;
			PUTCHAR(restore, activeRangePos[1], ranges[j + MAX_GPU_CHARS]);

		} while ( j < rangeNumChars[1]);

		k++;
		PUTCHAR(restore, activeRangePos[2], ranges[k + 2 * MAX_GPU_CHARS]);

		PUTCHAR(restore, activeRangePos[1], ranges[MAX_GPU_CHARS]);
		j = 0;

	} while( k < rangeNumChars[2]);
}