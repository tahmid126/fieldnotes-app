package com.fieldnotes.note;

import com.fieldnotes.common.exception.ResourceNotFoundException;
import com.fieldnotes.note.dto.FieldNoteRequest;
import com.fieldnotes.note.dto.FieldNoteResponse;
import com.fieldnotes.site.Site;
import com.fieldnotes.site.SiteRepository;
import com.fieldnotes.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FieldNoteService {

    private final FieldNoteRepository fieldNoteRepository;
    private final SiteRepository siteRepository;

    @Transactional(readOnly = true)
    public List<FieldNoteResponse> getNotes(User user, String status, UUID siteId, String query) {
        // If filters or search query are provided
        if ((status != null && !status.trim().isEmpty()) || siteId != null || (query != null && !query.trim().isEmpty())) {
            String sanitizedQuery = (query != null && !query.trim().isEmpty()) ? query.trim() : null;
            String sanitizedStatus = (status != null && !status.trim().isEmpty()) ? status.trim() : null;

            return fieldNoteRepository.searchAndFilterNotes(user.getId(), sanitizedStatus, siteId, sanitizedQuery)
                    .stream()
                    .map(FieldNoteResponse::fromEntity)
                    .collect(Collectors.toList());
        }

        return fieldNoteRepository.findAllByUserIdAndDeletedFalseOrderByNoteDateTimeDesc(user.getId())
                .stream()
                .map(FieldNoteResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public FieldNoteResponse getNoteById(UUID id, User user) {
        FieldNote note = fieldNoteRepository.findByIdAndUserIdAndDeletedFalse(id, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Field note not found with id: " + id));
        return FieldNoteResponse.fromEntity(note);
    }

    @Transactional
    public FieldNoteResponse createNote(FieldNoteRequest request, User user) {
        Site site = siteRepository.findByIdAndUserIdAndDeletedFalse(request.getSiteId(), user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Site not found with id: " + request.getSiteId()));

        LocalDateTime noteDateTime = request.getNoteDateTime() != null ? request.getNoteDateTime() : LocalDateTime.now();

        FieldNote note = FieldNote.builder()
                .id(request.getId() != null ? request.getId() : UUID.randomUUID())
                .title(request.getTitle().trim())
                .description(request.getDescription())
                .location(request.getLocation())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .noteDateTime(noteDateTime)
                .status(request.getStatus().trim().toUpperCase())
                .photoUrl(request.getPhotoUrl())
                .site(site)
                .user(user)
                .deleted(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        FieldNote saved = fieldNoteRepository.save(note);
        return FieldNoteResponse.fromEntity(saved);
    }

    @Transactional
    public FieldNoteResponse updateNote(UUID id, FieldNoteRequest request, User user) {
        FieldNote note = fieldNoteRepository.findByIdAndUserIdAndDeletedFalse(id, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Field note not found with id: " + id));

        Site site = siteRepository.findByIdAndUserIdAndDeletedFalse(request.getSiteId(), user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Site not found with id: " + request.getSiteId()));

        note.setTitle(request.getTitle().trim());
        note.setDescription(request.getDescription());
        note.setLocation(request.getLocation());
        note.setLatitude(request.getLatitude());
        note.setLongitude(request.getLongitude());
        if (request.getNoteDateTime() != null) {
            note.setNoteDateTime(request.getNoteDateTime());
        }
        note.setStatus(request.getStatus().trim().toUpperCase());
        note.setPhotoUrl(request.getPhotoUrl());
        note.setSite(site);
        note.setUpdatedAt(LocalDateTime.now());

        FieldNote updated = fieldNoteRepository.save(note);
        return FieldNoteResponse.fromEntity(updated);
    }

    @Transactional
    public void deleteNote(UUID id, User user) {
        FieldNote note = fieldNoteRepository.findByIdAndUserIdAndDeletedFalse(id, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Field note not found with id: " + id));

        note.setDeleted(true);
        note.setUpdatedAt(LocalDateTime.now());
        fieldNoteRepository.save(note);
    }
}
