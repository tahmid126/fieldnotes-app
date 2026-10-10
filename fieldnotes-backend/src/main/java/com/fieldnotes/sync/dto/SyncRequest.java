package com.fieldnotes.sync.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SyncRequest {

    private LocalDateTime lastSyncTimestamp;

    @Builder.Default
    private List<SyncCustomerItem> customers = new ArrayList<>();

    @Builder.Default
    private List<SyncSiteItem> sites = new ArrayList<>();

    @Builder.Default
    private List<SyncNoteItem> notes = new ArrayList<>();

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SyncCustomerItem {
        private UUID id;
        private String name;
        private String contactInformation;
        private boolean deleted;
        private LocalDateTime updatedAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SyncSiteItem {
        private UUID id;
        private String name;
        private String address;
        private UUID customerId;
        private boolean deleted;
        private LocalDateTime updatedAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SyncNoteItem {
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
        private boolean deleted;
        private LocalDateTime updatedAt;
    }
}
