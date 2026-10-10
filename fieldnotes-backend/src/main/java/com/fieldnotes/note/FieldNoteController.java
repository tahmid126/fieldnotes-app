package com.fieldnotes.note;

import com.fieldnotes.common.dto.ApiResponse;
import com.fieldnotes.note.dto.FieldNoteRequest;
import com.fieldnotes.note.dto.FieldNoteResponse;
import com.fieldnotes.security.SecurityUtils;
import com.fieldnotes.user.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/notes")
@RequiredArgsConstructor
public class FieldNoteController {

    private final FieldNoteService fieldNoteService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<FieldNoteResponse>>> getNotes(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) UUID siteId,
            @RequestParam(required = false) String query) {
        User user = SecurityUtils.getCurrentUser();
        List<FieldNoteResponse> notes = fieldNoteService.getNotes(user, status, siteId, query);
        return ResponseEntity.ok(ApiResponse.success(notes));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<FieldNoteResponse>> getNoteById(@PathVariable UUID id) {
        User user = SecurityUtils.getCurrentUser();
        FieldNoteResponse note = fieldNoteService.getNoteById(id, user);
        return ResponseEntity.ok(ApiResponse.success(note));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<FieldNoteResponse>> createNote(@Valid @RequestBody FieldNoteRequest request) {
        User user = SecurityUtils.getCurrentUser();
        FieldNoteResponse created = fieldNoteService.createNote(request, user);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Field note created successfully", created));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<FieldNoteResponse>> updateNote(
            @PathVariable UUID id,
            @Valid @RequestBody FieldNoteRequest request) {
        User user = SecurityUtils.getCurrentUser();
        FieldNoteResponse updated = fieldNoteService.updateNote(id, request, user);
        return ResponseEntity.ok(ApiResponse.success("Field note updated successfully", updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteNote(@PathVariable UUID id) {
        User user = SecurityUtils.getCurrentUser();
        fieldNoteService.deleteNote(id, user);
        return ResponseEntity.ok(ApiResponse.success("Field note deleted successfully", null));
    }
}
