package com.fieldnotes.note.dto;

import com.fieldnotes.note.FieldNote;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FieldNoteResponse {

    private UUID id;
    private String title;
    private String description;
    private String location;
    private Double latitude;
    private Double longitude;
    private LocalDateTime noteDateTime;
    private String status;
    private String photoUrl;
    private UUID siteId;
    private String siteName;
    private UUID customerId;
    private String customerName;
    private boolean deleted;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static FieldNoteResponse fromEntity(FieldNote note) {
        UUID siteId = note.getSite() != null ? note.getSite().getId() : null;
        String siteName = note.getSite() != null ? note.getSite().getName() : null;
        UUID customerId = null;
        String customerName = null;
        if (note.getSite() != null && note.getSite().getCustomer() != null) {
            customerId = note.getSite().getCustomer().getId();
            customerName = note.getSite().getCustomer().getName();
        }

        return FieldNoteResponse.builder()
                .id(note.getId())
                .title(note.getTitle())
                .description(note.getDescription())
                .location(note.getLocation())
                .latitude(note.getLatitude())
                .longitude(note.getLongitude())
                .noteDateTime(note.getNoteDateTime())
                .status(note.getStatus())
                .photoUrl(note.getPhotoUrl())
                .siteId(siteId)
                .siteName(siteName)
                .customerId(customerId)
                .customerName(customerName)
                .deleted(note.isDeleted())
                .createdAt(note.getCreatedAt())
                .updatedAt(note.getUpdatedAt())
                .build();
    }
}
