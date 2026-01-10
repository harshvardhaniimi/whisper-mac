#ifndef WHISPER_BRIDGE_H
#define WHISPER_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

// This is a bridge header for whisper.cpp
// The actual whisper.cpp implementation will be added as a git submodule

// Forward declarations for whisper.cpp types
struct whisper_context;
struct whisper_full_params;

// Core functions
struct whisper_context * whisper_init_from_file(const char * path_model);
void whisper_free(struct whisper_context * ctx);

// Transcription functions
int whisper_full(
    struct whisper_context * ctx,
    struct whisper_full_params params,
    const float * samples,
    int n_samples
);

int whisper_full_n_segments(struct whisper_context * ctx);
const char * whisper_full_get_segment_text(struct whisper_context * ctx, int i_segment);

// Parameter functions
struct whisper_full_params whisper_full_default_params(int strategy);

// Sampling strategies
enum whisper_sampling_strategy {
    WHISPER_SAMPLING_GREEDY = 0,
    WHISPER_SAMPLING_BEAM_SEARCH = 1,
};

#ifdef __cplusplus
}
#endif

#endif // WHISPER_BRIDGE_H
