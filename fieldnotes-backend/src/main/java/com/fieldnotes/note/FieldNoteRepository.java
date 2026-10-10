package com.fieldnotes.note;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FieldNoteRepository extends JpaRepository<FieldNote, UUID> {

    List<FieldNote> findAllByUserIdAndDeletedFalseOrderByNoteDateTimeDesc(UUID userId);

    Optional<FieldNote> findByIdAndUserIdAndDeletedFalse(UUID id, UUID userId);

    @Query("SELECT n FROM FieldNote n " +
           "JOIN n.site s " +
           "JOIN s.customer c " +
           "WHERE n.user.id = :userId " +
           "AND n.deleted = false " +
           "AND (:status IS NULL OR LOWER(n.status) = LOWER(:status)) " +
           "AND (:siteId IS NULL OR s.id = :siteId) " +
           "AND (:query IS NULL OR (" +
           "     LOWER(n.title) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "     (n.description IS NOT NULL AND LOWER(n.description) LIKE LOWER(CONCAT('%', :query, '%'))) OR " +
           "     LOWER(s.name) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "     LOWER(c.name) LIKE LOWER(CONCAT('%', :query, '%'))" +
           ")) " +
           "ORDER BY n.noteDateTime DESC")
    List<FieldNote> searchAndFilterNotes(
            @Param("userId") UUID userId,
            @Param("status") String status,
            @Param("siteId") UUID siteId,
            @Param("query") String query);

    List<FieldNote> findByUserIdAndUpdatedAtAfter(UUID userId, LocalDateTime updatedAt);

    List<FieldNote> findAllByUserId(UUID userId);
}
