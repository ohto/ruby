package com.worksap.company.framework.autoindex.offline;

import java.util.List;
import java.util.Optional;
import java.util.function.IntToLongFunction;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import java.util.stream.Stream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.datastax.driver.core.Row;
import com.datastax.spark.connector.ColumnName;
import com.datastax.spark.connector.NamedColumnRef;
import com.datastax.spark.connector.WriteTime;
import com.datastax.spark.connector.japi.CassandraJavaUtil;
import com.datastax.spark.connector.japi.CassandraRow;
import com.google.common.base.CaseFormat;
import com.worksap.company.access.cassandra.DTOCacheEntity;
import com.worksap.company.access.cassandra.DTOCacheUtil;
import com.worksap.company.access.cassandra.DTOColumn;
import com.worksap.company.access.cassandra.SerializeUtil;
import com.worksap.company.dto.annotation.Key;

final class KvaUtil {

    private static final Logger LOGGER = LoggerFactory.getLogger(KvaUtil.class);

    private KvaUtil() {
        // prohibit instantiation
    }

    static List<ColumnName> createNormalSelectors(Class<?> clazz) {
        final DTOCacheEntity metadata = getMetadata(clazz);
        return metadata.getAllConvertedColumnNames()
                .stream()
                .map(CassandraJavaUtil::column)
                .collect(Collectors.toList());
    }

    static List<WriteTime> createWriteTimeSelectors(Class<?> clazz) {
        final DTOCacheEntity metadata = getMetadata(clazz);
        return metadata.getColumns().stream().map(DTOColumn::getField)
                .filter(field -> field.getAnnotation(Key.class) == null)
                .map(field -> CaseFormat.LOWER_CAMEL.to(CaseFormat.LOWER_UNDERSCORE, field.getName()))
                .map(CassandraJavaUtil::writeTime)
                .collect(Collectors.toList());
    }

    static List<NamedColumnRef> combinedSelectors(Class<?> clazz) {
        return concat(createNormalSelectors(clazz), createWriteTimeSelectors(clazz), NamedColumnRef.class);
    }

    private static <T> List<T> concat(List<? extends T> as, List<? extends T> bs, Class<T> clazz) {
        return Stream.concat(as.stream(), bs.stream()).collect(Collectors.toList());
    }

    static DTOCacheEntity getMetadata(Class<?> clazz) {
        final DTOCacheEntity metadata = DTOCacheUtil.getDTOCache(clazz);
        if (metadata == null) {
            throw new IllegalArgumentException(clazz.toString() + " is not a valid KVA dto");
        }
        return metadata;
    }

    static String getTableName(Class<?> clazz) {

        DTOCacheEntity dtoCacheMetadata = DTOCacheUtil.getDTOCache(clazz);

        return dtoCacheMetadata.getCfName();

    }

    static <T> T convert(CassandraRow cassandraRow, Class<T> clazz) {
        final DTOCacheEntity metadata = getMetadata(clazz);
        final Row row = new CassandraRowBackedDatastaxRow(cassandraRow);
        return SerializeUtil.getByEntity(row, clazz, metadata);
    }

    static <T> EntityWithTimestamp<T> convertWithTimestamp(CassandraRow cassandraRow, Class<T> clazz) {
        final T entity = convert(cassandraRow, clazz);
        final int n = createNormalSelectors(clazz).size();
        final int m = createWriteTimeSelectors(clazz).size();
        final IntToLongFunction getTimestamp = i -> Optional.ofNullable(cassandraRow.getLong(i)).orElse(-1L);
        final long maximumTimestamp = IntStream
                .range(n, n + m)
                .mapToLong(getTimestamp)
                .max()
                .orElse(-1L);
        return new EntityWithTimestamp<>(entity, maximumTimestamp);
    }

    @lombok.Value
    static class EntityWithTimestamp<T> {
        T entity;
        long timestamp;
    }

}
