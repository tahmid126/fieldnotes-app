package com.fieldnotes.note.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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
public class FieldNoteRequest {

    private UUID id; // Optional (offline sync)

    @NotBlank(message = "Title is required")
    private String title;

    private String description;

    private String location;

    private Double latitude;

    private Double longitude;

    private LocalDateTime noteDateTime;

    @NotBlank(message = "Status is required")
    private String status;

    private String photoUrl;

    @NotNull(message = "Site ID is required")
    private UUID siteId;
}
